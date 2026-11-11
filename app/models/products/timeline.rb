# ลำดับเหตุการณ์ของสินค้า (สร้าง → ส่งตรวจ → ผลตรวจ → ส่งใหม่ ...) สำหรับแสดง timeline
#
# ข้อจำกัดของข้อมูล: ระบบเก็บเวลา "ส่งตรวจ" แค่ครั้งล่าสุด (products.submitted_at ถูกเขียนทับทุกครั้งที่ส่งใหม่)
# รอบก่อนหน้าจึงแสดงเป็นเหตุการณ์ที่ไม่มีเวลา (at = nil) แทนที่จะแต่งเวลาขึ้นมาเอง
#
# audience: :seller ไม่ได้ข้อมูลผู้ตรวจ (ผู้ขายต้องไม่เห็นตัวตน Admin) — :admin ได้ผู้ตรวจและเหตุผล
module Products
  class Timeline
    Event = Struct.new(:kind, :label, :at, :reason, :reviewer, keyword_init: true)

    AUDIENCES = %i[seller admin].freeze

    def initialize(product, audience:)
      raise ArgumentError, "unknown audience: #{audience.inspect}" unless AUDIENCES.include?(audience)

      @product = product
      @audience = audience
    end

    def events
      reviews = @product.reviews.to_a
      list = [ Event.new(kind: :created, label: "สร้างฉบับร่าง", at: @product.created_at) ]

      if reviews.empty?
        list << submission_event(0, @product.submitted_at) if @product.submitted_at
      else
        reviews.each_with_index do |review, index|
          list << submission_event(index, known_submission_time_before(review, last: index == reviews.size - 1))
          list << review_event(review)
        end
        list << pending_resubmission_event if resubmitted_after?(reviews.last)
      end

      list
    end

    private

    def submission_event(round, at)
      if round.zero?
        Event.new(kind: :submitted, label: "ส่งตรวจสอบ", at: at)
      else
        Event.new(kind: :resubmitted, label: "ส่งใหม่", at: at)
      end
    end

    # submitted_at เป็นของรอบล่าสุดเท่านั้น — ใช้ได้เมื่อมันเกิดก่อนผลตรวจล่าสุด
    def known_submission_time_before(review, last:)
      submitted_at = @product.submitted_at
      submitted_at if last && submitted_at && submitted_at < review.created_at
    end

    def resubmitted_after?(last_review)
      @product.pending_review? && @product.submitted_at && @product.submitted_at > last_review.created_at
    end

    def pending_resubmission_event
      Event.new(kind: :resubmitted, label: "ส่งใหม่ รอตรวจสอบ", at: @product.submitted_at)
    end

    def review_event(review)
      Event.new(
        kind: review.decision.to_sym,
        label: review.rejected? ? "ไม่อนุมัติ" : "อนุมัติแล้ว",
        at: review.created_at,
        reason: review.reason,
        reviewer: (review.reviewer if @audience == :admin)
      )
    end
  end
end
