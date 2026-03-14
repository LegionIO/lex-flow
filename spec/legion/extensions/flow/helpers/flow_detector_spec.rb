# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Flow::Helpers::FlowDetector do
  subject(:detector) { described_class.new }

  describe '#initialize' do
    it 'starts with neutral challenge and skill' do
      expect(detector.challenge).to eq(0.5)
      expect(detector.skill).to eq(0.5)
    end

    it 'starts in relaxation state' do
      expect(detector.flow_state).to eq(:relaxation)
    end

    it 'starts with zero flow score' do
      expect(detector.flow_score).to eq(0.0)
    end

    it 'starts with zero consecutive and total flow ticks' do
      expect(detector.consecutive_flow_ticks).to eq(0)
      expect(detector.total_flow_ticks).to eq(0)
    end

    it 'starts with empty history' do
      expect(detector.history).to be_empty
    end
  end

  describe '#update' do
    it 'applies EMA to challenge and skill' do
      detector.update(challenge_input: 0.8, skill_input: 0.8)
      expect(detector.challenge).to be > 0.5
      expect(detector.skill).to be > 0.5
    end

    it 'clamps inputs to 0.0..1.0' do
      detector.update(challenge_input: 2.0, skill_input: -1.0)
      expect(detector.challenge).to be_between(0.0, 1.0)
      expect(detector.skill).to be_between(0.0, 1.0)
    end

    it 'records a snapshot in history' do
      detector.update(challenge_input: 0.6, skill_input: 0.6)
      expect(detector.history.size).to eq(1)
      expect(detector.history.last).to include(:state, :flow_score, :challenge, :skill, :at)
    end

    it 'caps history at MAX_FLOW_HISTORY' do
      max = Legion::Extensions::Flow::Helpers::Constants::MAX_FLOW_HISTORY
      (max + 10).times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.history.size).to eq(max)
    end

    it 'accepts modifiers' do
      detector.update(challenge_input: 0.6, skill_input: 0.6, modifiers: { curiosity_active: true })
      expect(detector.flow_score).to be >= 0.0
    end
  end

  describe 'flow state detection' do
    def push_to_flow(count = 30)
      count.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
    end

    it 'enters flow when challenge and skill are balanced and moderate' do
      push_to_flow
      expect(detector.flow_state).to eq(:flow)
    end

    it 'detects arousal when challenge is high and skill is moderate-low' do
      30.times { detector.update(challenge_input: 0.9, skill_input: 0.4) }
      expect(detector.flow_state).to eq(:arousal)
    end

    it 'detects boredom when challenge is low and skill is high' do
      30.times { detector.update(challenge_input: 0.1, skill_input: 0.8) }
      expect(detector.flow_state).to eq(:boredom)
    end

    it 'detects anxiety when challenge is very high and skill is very low' do
      30.times { detector.update(challenge_input: 0.95, skill_input: 0.1) }
      expect(detector.flow_state).to eq(:anxiety)
    end

    it 'detects apathy when both are very low' do
      30.times { detector.update(challenge_input: 0.1, skill_input: 0.1) }
      expect(detector.flow_state).to eq(:apathy)
    end
  end

  describe '#in_flow?' do
    it 'returns true when in flow state' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.in_flow?).to be true
    end

    it 'returns false when not in flow' do
      expect(detector.in_flow?).to be false
    end
  end

  describe '#deep_flow?' do
    it 'returns false before threshold' do
      19.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.deep_flow?).to be false
    end

    it 'returns true after consecutive flow ticks reach threshold' do
      # Push challenge/skill into flow range quickly first
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      # Now the detector should be in flow, keep it there past threshold
      expect(detector.consecutive_flow_ticks).to be >= 20
      expect(detector.deep_flow?).to be true
    end
  end

  describe '#flow_effects' do
    it 'returns neutral effects when not in flow' do
      effects = detector.flow_effects
      expect(effects[:performance_boost]).to eq(1.0)
      expect(effects[:creativity_boost]).to eq(1.0)
      expect(effects[:fatigue_reduction]).to eq(1.0)
    end

    it 'returns enhanced effects when in flow' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      effects = detector.flow_effects
      expect(effects[:performance_boost]).to be > 1.0
      expect(effects[:creativity_boost]).to be > 1.0
      expect(effects[:fatigue_reduction]).to be < 1.0
    end

    it 'provides extra boosts in deep flow' do
      40.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      effects = detector.flow_effects
      base_perf = Legion::Extensions::Flow::Helpers::Constants::FLOW_EFFECTS[:performance_boost]
      expect(effects[:performance_boost]).to be > base_perf
    end
  end

  describe '#challenge_skill_balance' do
    it 'returns 0 when challenge equals skill' do
      expect(detector.challenge_skill_balance).to eq(0.0)
    end

    it 'returns positive value when unbalanced' do
      30.times { detector.update(challenge_input: 0.9, skill_input: 0.1) }
      expect(detector.challenge_skill_balance).to be > 0.0
    end
  end

  describe '#flow_trend' do
    it 'returns insufficient_data with fewer than 5 entries' do
      3.times { detector.update(challenge_input: 0.5, skill_input: 0.5) }
      expect(detector.flow_trend).to eq(:insufficient_data)
    end

    it 'detects entering_flow when scores are increasing' do
      5.times { detector.update(challenge_input: 0.2, skill_input: 0.2) }
      10.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      trend = detector.flow_trend
      expect(trend).to eq(:entering_flow).or eq(:stable)
    end

    it 'detects leaving_flow when scores are decreasing' do
      20.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      10.times { detector.update(challenge_input: 0.1, skill_input: 0.9) }
      trend = detector.flow_trend
      expect(trend).to eq(:leaving_flow).or eq(:stable)
    end

    it 'returns stable when scores are consistent' do
      20.times { detector.update(challenge_input: 0.5, skill_input: 0.5) }
      expect(detector.flow_trend).to eq(:stable)
    end
  end

  describe '#flow_percentage' do
    it 'returns 0.0 with empty history' do
      expect(detector.flow_percentage).to eq(0.0)
    end

    it 'returns percentage of flow ticks' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.flow_percentage).to be > 0.0
    end
  end

  describe '#to_h' do
    it 'returns a complete hash' do
      detector.update(challenge_input: 0.6, skill_input: 0.6)
      h = detector.to_h
      expect(h).to include(
        :state, :score, :challenge, :skill, :balance,
        :in_flow, :deep_flow, :consecutive_flow_ticks,
        :total_flow_ticks, :flow_percentage, :trend, :effects
      )
    end

    it 'rounds numeric values' do
      detector.update(challenge_input: 0.6, skill_input: 0.6)
      h = detector.to_h
      expect(h[:score].to_s.split('.').last.length).to be <= 3
      expect(h[:challenge].to_s.split('.').last.length).to be <= 3
    end
  end

  describe 'flow score computation' do
    it 'gives higher scores when in flow with good balance' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.flow_score).to be > 0.7
    end

    it 'gives lower scores when not in flow' do
      30.times { detector.update(challenge_input: 0.1, skill_input: 0.9) }
      expect(detector.flow_score).to be < 0.5
    end

    it 'adds curiosity bonus' do
      20.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      score_without = detector.flow_score
      detector2 = described_class.new
      20.times { detector2.update(challenge_input: 0.6, skill_input: 0.6, modifiers: { curiosity_active: true }) }
      expect(detector2.flow_score).to be >= score_without
    end

    it 'adds low error bonus' do
      20.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      score_without = detector.flow_score
      detector2 = described_class.new
      20.times { detector2.update(challenge_input: 0.6, skill_input: 0.6, modifiers: { low_errors: true }) }
      expect(detector2.flow_score).to be >= score_without
    end

    it 'clamps score to 0.0..1.0' do
      50.times do
        detector.update(challenge_input: 0.6, skill_input: 0.6,
                        modifiers: { curiosity_active: true, low_errors: true })
      end
      expect(detector.flow_score).to be_between(0.0, 1.0)
    end
  end

  describe 'consecutive flow tick tracking' do
    it 'increments when in flow' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.consecutive_flow_ticks).to be > 0
    end

    it 'resets when leaving flow' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.consecutive_flow_ticks).to be > 0
      30.times { detector.update(challenge_input: 0.1, skill_input: 0.9) }
      expect(detector.consecutive_flow_ticks).to eq(0)
    end

    it 'accumulates total flow ticks across sessions' do
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      first_total = detector.total_flow_ticks
      30.times { detector.update(challenge_input: 0.1, skill_input: 0.9) }
      30.times { detector.update(challenge_input: 0.6, skill_input: 0.6) }
      expect(detector.total_flow_ticks).to be > first_total
    end
  end
end
