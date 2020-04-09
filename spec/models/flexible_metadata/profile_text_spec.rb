# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlexibleMetadata::ProfileText, type: :model do
  let(:profile_text) { FactoryBot.build(:flexible_metadata_profile_text) }

  it 'is valid' do
    expect(profile_text).to be_valid
  end
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }
  end
  describe 'associations' do
    it { is_expected.to belong_to(:textable).optional }
  end
end
