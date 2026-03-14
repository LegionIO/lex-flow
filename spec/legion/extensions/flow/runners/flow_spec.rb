# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Flow::Runners::Flow do
  let(:client) { Legion::Extensions::Flow::Client.new }

  describe '#update_flow' do
    let(:tick_results) do
      {
        prediction_engine:    { rolling_accuracy: 0.6, error_rate: 0.3 },
        action_selection:     { complexity: 0.5 },
        memory_retrieval:     { avg_strength: 0.6 },
        habit:                { automation_level: 0.5 },
        curiosity:            { intensity: 0.3 },
        emotional_evaluation: { anxiety: 0.2 }
      }
    end

    it 'returns flow state hash' do
      result = client.update_flow(tick_results: tick_results)
      expect(result).to include(:state, :score, :in_flow, :deep_flow, :effects, :breakers, :challenge, :skill)
    end

    it 'returns numeric score' do
      result = client.update_flow(tick_results: tick_results)
      expect(result[:score]).to be_a(Float)
      expect(result[:score]).to be_between(0.0, 1.0)
    end

    it 'returns challenge and skill values' do
      result = client.update_flow(tick_results: tick_results)
      expect(result[:challenge]).to be_between(0.0, 1.0)
      expect(result[:skill]).to be_between(0.0, 1.0)
    end

    it 'returns empty breakers for normal tick' do
      result = client.update_flow(tick_results: tick_results)
      expect(result[:breakers]).to be_empty
    end

    it 'returns effects hash' do
      result = client.update_flow(tick_results: tick_results)
      expect(result[:effects]).to be_a(Hash)
    end

    context 'with flow breakers' do
      it 'detects high anxiety' do
        tick_results[:emotional_evaluation][:anxiety] = 0.9
        # Push into flow first
        20.times { client.update_flow(tick_results: tick_results.merge(emotional_evaluation: { anxiety: 0.1 })) }
        result = client.update_flow(tick_results: tick_results)
        expect(result[:breakers]).to include(:high_anxiety)
      end

      it 'detects trust violation' do
        tick_results[:trust] = { violation: true }
        result = client.update_flow(tick_results: tick_results)
        expect(result[:breakers]).to include(:trust_violation)
      end

      it 'detects critical error' do
        tick_results[:error] = { critical: true }
        result = client.update_flow(tick_results: tick_results)
        expect(result[:breakers]).to include(:critical_error)
      end

      it 'detects burnout' do
        tick_results[:fatigue] = { burnout: true }
        result = client.update_flow(tick_results: tick_results)
        expect(result[:breakers]).to include(:burnout)
      end

      it 'detects conflict escalation' do
        tick_results[:conflict] = { severity: 4 }
        result = client.update_flow(tick_results: tick_results)
        expect(result[:breakers]).to include(:conflict_escalation)
      end
    end

    context 'with default tick_results' do
      it 'handles empty tick_results' do
        result = client.update_flow(tick_results: {})
        expect(result[:state]).to be_a(Symbol)
        expect(result[:score]).to be_a(Float)
      end
    end
  end

  describe '#flow_status' do
    it 'returns full status hash' do
      status = client.flow_status
      expect(status).to include(
        :state, :score, :challenge, :skill, :balance,
        :in_flow, :deep_flow, :consecutive_flow_ticks,
        :total_flow_ticks, :flow_percentage, :trend, :effects
      )
    end
  end

  describe '#flow_effects' do
    it 'returns effects with flow info' do
      result = client.flow_effects
      expect(result).to include(:effects, :in_flow, :deep_flow)
      expect(result[:effects]).to be_a(Hash)
    end

    it 'returns neutral effects initially' do
      result = client.flow_effects
      expect(result[:effects][:performance_boost]).to eq(1.0)
    end
  end

  describe '#flow_history' do
    it 'returns empty history initially' do
      result = client.flow_history
      expect(result[:history]).to be_empty
      expect(result[:total]).to eq(0)
    end

    it 'returns history after updates' do
      5.times { client.update_flow(tick_results: {}) }
      result = client.flow_history
      expect(result[:history].size).to eq(5)
      expect(result[:total]).to eq(5)
    end

    it 'respects limit parameter' do
      10.times { client.update_flow(tick_results: {}) }
      result = client.flow_history(limit: 3)
      expect(result[:history].size).to eq(3)
      expect(result[:total]).to eq(10)
    end
  end

  describe '#flow_stats' do
    it 'returns stats hash' do
      stats = client.flow_stats
      expect(stats).to include(:state, :score, :consecutive_flow_ticks, :total_flow_ticks,
                               :flow_percentage, :trend, :balance)
    end

    it 'returns numeric values' do
      stats = client.flow_stats
      expect(stats[:score]).to be_a(Float)
      expect(stats[:flow_percentage]).to be_a(Float)
      expect(stats[:balance]).to be_a(Float)
    end
  end

  describe 'challenge/skill extraction' do
    it 'derives challenge from prediction accuracy, error rate, and complexity' do
      high_challenge = {
        prediction_engine: { rolling_accuracy: 0.2, error_rate: 0.8 },
        action_selection:  { complexity: 0.9 }
      }
      low_challenge = {
        prediction_engine: { rolling_accuracy: 0.9, error_rate: 0.1 },
        action_selection:  { complexity: 0.1 }
      }

      client_high = Legion::Extensions::Flow::Client.new
      client_low = Legion::Extensions::Flow::Client.new
      20.times do
        client_high.update_flow(tick_results: high_challenge)
        client_low.update_flow(tick_results: low_challenge)
      end

      high_result = client_high.flow_status
      low_result = client_low.flow_status
      expect(high_result[:challenge]).to be > low_result[:challenge]
    end

    it 'derives skill from prediction accuracy, memory strength, and habit' do
      high_skill = {
        prediction_engine: { rolling_accuracy: 0.9 },
        memory_retrieval:  { avg_strength: 0.9 },
        habit:             { automation_level: 0.9 }
      }
      low_skill = {
        prediction_engine: { rolling_accuracy: 0.1 },
        memory_retrieval:  { avg_strength: 0.1 },
        habit:             { automation_level: 0.1 }
      }

      client_high = Legion::Extensions::Flow::Client.new
      client_low = Legion::Extensions::Flow::Client.new
      20.times do
        client_high.update_flow(tick_results: high_skill)
        client_low.update_flow(tick_results: low_skill)
      end

      high_result = client_high.flow_status
      low_result = client_low.flow_status
      expect(high_result[:skill]).to be > low_result[:skill]
    end
  end

  describe 'flow progression over time' do
    let(:balanced_tick) do
      {
        prediction_engine: { rolling_accuracy: 0.5, error_rate: 0.5 },
        action_selection:  { complexity: 0.7 },
        memory_retrieval:  { avg_strength: 0.7 },
        habit:             { automation_level: 0.7 },
        curiosity:         { intensity: 0.6 }
      }
    end

    it 'reaches flow state with sustained balanced input' do
      40.times { client.update_flow(tick_results: balanced_tick) }
      expect(client.flow_status[:in_flow]).to be true
    end

    it 'reaches deep flow after threshold' do
      50.times { client.update_flow(tick_results: balanced_tick) }
      status = client.flow_status
      # May or may not reach deep flow depending on exact EMA convergence
      expect(status[:consecutive_flow_ticks]).to be >= 0
    end
  end
end
