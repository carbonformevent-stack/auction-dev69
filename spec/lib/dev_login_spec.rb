require "rails_helper"

RSpec.describe DevLogin do
  describe "ACCOUNTS" do
    it "offers one seller and one admin" do
      expect(described_class::ACCOUNTS.transform_values { |account| account[:role] }).to eq("seller" => :user, "admin" => :admin)
    end

    it "uses the reserved .test domain so a real mailbox can never match" do
      emails = [ *described_class::ACCOUNTS.values, described_class::OTHER_SELLER ].pluck(:email)

      expect(emails).to all(end_with("@example.test"))
    end

    it "gives every account a distinct email and uid" do
      accounts = [ *described_class::ACCOUNTS.values, described_class::OTHER_SELLER ]

      expect([ accounts.pluck(:email).uniq.size, accounts.pluck(:uid).uniq.size ]).to eq([ 3, 3 ])
    end
  end

  describe ".enabled?" do
    def stub_env(rails_env:, flag:)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(rails_env))
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEV_LOGIN").and_return(flag)
    end

    it "is on in development when DEV_LOGIN=1" do
      stub_env(rails_env: "development", flag: "1")

      expect(described_class).to be_enabled
    end

    it "is off in development unless it was asked for" do
      stub_env(rails_env: "development", flag: nil)

      expect(described_class).not_to be_enabled
    end

    it "is off for any value other than 1" do
      stub_env(rails_env: "development", flag: "true")

      expect(described_class).not_to be_enabled
    end

    %w[test production staging].each do |environment|
      it "is never on in #{environment}, even with DEV_LOGIN=1" do
        stub_env(rails_env: environment, flag: "1")

        expect(described_class).not_to be_enabled
      end
    end
  end
end
