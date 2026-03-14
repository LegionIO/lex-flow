# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Flow::Helpers::Constants do
  describe 'FLOW_STATES' do
    it 'contains all eight Csikszentmihalyi states' do
      expect(described_class::FLOW_STATES).to contain_exactly(
        :flow, :arousal, :control, :relaxation, :boredom, :apathy, :worry, :anxiety
      )
    end

    it 'is frozen' do
      expect(described_class::FLOW_STATES).to be_frozen
    end
  end

  describe 'FLOW_ZONE' do
    it 'defines challenge and skill boundaries' do
      zone = described_class::FLOW_ZONE
      expect(zone[:challenge_min]).to eq(0.4)
      expect(zone[:challenge_max]).to eq(0.8)
      expect(zone[:skill_min]).to eq(0.4)
      expect(zone[:skill_max]).to eq(0.8)
    end

    it 'defines balance tolerance' do
      expect(described_class::FLOW_ZONE[:balance_tolerance]).to eq(0.15)
    end

    it 'is frozen' do
      expect(described_class::FLOW_ZONE).to be_frozen
    end
  end

  describe 'FLOW_ALPHA' do
    it 'is 0.15' do
      expect(described_class::FLOW_ALPHA).to eq(0.15)
    end
  end

  describe 'DEEP_FLOW_THRESHOLD' do
    it 'is 20 consecutive ticks' do
      expect(described_class::DEEP_FLOW_THRESHOLD).to eq(20)
    end
  end

  describe 'FLOW_EFFECTS' do
    it 'defines performance and creativity boosts' do
      effects = described_class::FLOW_EFFECTS
      expect(effects[:performance_boost]).to eq(1.15)
      expect(effects[:creativity_boost]).to eq(1.2)
    end

    it 'defines fatigue reduction' do
      expect(described_class::FLOW_EFFECTS[:fatigue_reduction]).to eq(0.5)
    end

    it 'is frozen' do
      expect(described_class::FLOW_EFFECTS).to be_frozen
    end
  end

  describe 'FLOW_BREAKERS' do
    it 'contains five breaker types' do
      expect(described_class::FLOW_BREAKERS.size).to eq(5)
      expect(described_class::FLOW_BREAKERS).to include(:high_anxiety, :burnout, :trust_violation)
    end

    it 'is frozen' do
      expect(described_class::FLOW_BREAKERS).to be_frozen
    end
  end

  describe 'STATE_REGIONS' do
    it 'defines eight regions' do
      expect(described_class::STATE_REGIONS.size).to eq(8)
    end

    it 'marks only flow as balanced' do
      balanced = described_class::STATE_REGIONS.select { |_, v| v[:balanced] }.keys
      expect(balanced).to eq([:flow])
    end

    it 'uses Range objects for challenge and skill' do
      described_class::STATE_REGIONS.each_value do |region|
        expect(region[:challenge]).to be_a(Range)
        expect(region[:skill]).to be_a(Range)
      end
    end
  end

  describe 'score bonuses' do
    it 'defines deep flow bonus' do
      expect(described_class::DEEP_FLOW_BONUS).to eq(0.1)
    end

    it 'defines curiosity bonus' do
      expect(described_class::CURIOSITY_BONUS).to eq(0.05)
    end

    it 'defines low error bonus' do
      expect(described_class::LOW_ERROR_BONUS).to eq(0.05)
    end
  end

  describe 'MAX_FLOW_HISTORY' do
    it 'caps at 100' do
      expect(described_class::MAX_FLOW_HISTORY).to eq(100)
    end
  end
end
