# frozen_string_literal: true

module Legion
  module Extensions
    module Flow
      module Helpers
        module Constants
          # Flow states (Csikszentmihalyi's model)
          FLOW_STATES = %i[
            flow
            arousal
            control
            relaxation
            boredom
            apathy
            worry
            anxiety
          ].freeze

          # Input dimensions for flow detection
          DIMENSIONS = %i[challenge skill].freeze

          # Flow zone boundaries (challenge-skill space)
          # Flow occurs when challenge ~= skill and both are moderate-to-high
          FLOW_ZONE = {
            challenge_min:     0.4,
            challenge_max:     0.8,
            skill_min:         0.4,
            skill_max:         0.8,
            balance_tolerance: 0.15
          }.freeze

          # EMA alpha for challenge/skill tracking
          FLOW_ALPHA = 0.15

          # Minimum ticks in flow before "deep flow" bonus
          DEEP_FLOW_THRESHOLD = 20

          # Flow score bonuses
          DEEP_FLOW_BONUS = 0.1
          CURIOSITY_BONUS = 0.05
          LOW_ERROR_BONUS = 0.05

          # Flow effects on other subsystems
          FLOW_EFFECTS = {
            fatigue_reduction:    0.5,   # fatigue drains 50% slower in flow
            time_dilation:        0.7,   # subjective time flies (rate < 1.0)
            performance_boost:    1.15,  # 15% performance improvement
            attention_broadening: 0.8,   # attention threshold lowered (more open)
            creativity_boost:     1.2    # curiosity/imagination amplified
          }.freeze

          # Anti-flow indicators (break flow state)
          FLOW_BREAKERS = %i[
            high_anxiety
            trust_violation
            critical_error
            burnout
            conflict_escalation
          ].freeze

          # History cap
          MAX_FLOW_HISTORY = 100

          # State classification regions in challenge-skill space
          STATE_REGIONS = {
            flow:       { challenge: (0.4..0.8), skill: (0.4..0.8), balanced: true },
            arousal:    { challenge: (0.6..1.0), skill: (0.3..0.6), balanced: false },
            control:    { challenge: (0.2..0.5), skill: (0.5..0.8), balanced: false },
            relaxation: { challenge: (0.1..0.4), skill: (0.4..0.7), balanced: false },
            boredom:    { challenge: (0.0..0.3), skill: (0.5..1.0), balanced: false },
            apathy:     { challenge: (0.0..0.3), skill: (0.0..0.3), balanced: false },
            worry:      { challenge: (0.5..0.8), skill: (0.1..0.4), balanced: false },
            anxiety:    { challenge: (0.7..1.0), skill: (0.0..0.4), balanced: false }
          }.freeze
        end
      end
    end
  end
end
