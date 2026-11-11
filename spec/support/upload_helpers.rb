# ไฟล์สำหรับทดสอบการอัปโหลด — ไฟล์เล็กอยู่ใน spec/fixtures/files, ไฟล์ใหญ่สร้างตอนรัน
module UploadHelpers
  MAGIC = {
    "image/jpeg" => "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00".b,
    "application/pdf" => "%PDF-1.4\n".b
  }.freeze

  def fixture_upload(name, content_type = nil)
    Rack::Test::UploadedFile.new(file_fixture(name), content_type || Marcel::MimeType.for(name: name))
  end

  # ไฟล์ขนาด byte_size พอดี ขึ้นต้นด้วย magic bytes ของ content_type
  def sized_upload(byte_size, content_type:, filename:)
    magic = MAGIC.fetch(content_type)
    file = Tempfile.new([ "upload", File.extname(filename) ], binmode: true)
    file.write(magic + ("\x00".b * (byte_size - magic.bytesize)))
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, true, original_filename: filename)
  end

  def image_blob(name = "image.jpg")
    ActiveStorage::Blob.create_and_upload!(io: file_fixture(name).open, filename: name)
  end
end

RSpec.configure do |config|
  config.include UploadHelpers
  config.include ActionDispatch::TestProcess::FixtureFile
end
