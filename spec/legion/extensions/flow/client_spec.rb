# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Flow::Client do
  describe '#initialize' do
    it 'creates a default flow detector' do
      client = described_class.new
      expect(client.flow_detector).to be_a(Legion::Extensions::Flow::Helpers::FlowDetector)
    end

    it 'accepts an injected flow detector' do
      detector = Legion::Extensions::Flow::Helpers::FlowDetector.new
      client = described_class.new(flow_detector: detector)
      expect(client.flow_detector).to be(detector)
    end

    it 'ignores unknown keyword arguments' do
      expect { described_class.new(unknown: 'value') }.not_to raise_error
    end
  end

  describe 'runner integration' do
    it 'responds to update_flow' do
      expect(described_class.new).to respond_to(:update_flow)
    end

    it 'responds to flow_status' do
      expect(described_class.new).to respond_to(:flow_status)
    end

    it 'responds to flow_effects' do
      expect(described_class.new).to respond_to(:flow_effects)
    end

    it 'responds to flow_history' do
      expect(described_class.new).to respond_to(:flow_history)
    end

    it 'responds to flow_stats' do
      expect(described_class.new).to respond_to(:flow_stats)
    end
  end

  describe 'shared state across calls' do
    it 'accumulates flow state across multiple update_flow calls' do
      client = described_class.new
      tick = {
        prediction_engine: { rolling_accuracy: 0.6, error_rate: 0.2 },
        action_selection:  { complexity: 0.5 },
        memory_retrieval:  { avg_strength: 0.6 },
        habit:             { automation_level: 0.5 }
      }
      20.times { client.update_flow(tick_results: tick) }
      expect(client.flow_history[:total]).to eq(20)
    end
  end
end
