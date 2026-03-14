# frozen_string_literal: true

module Legion
  module Extensions
    module Flow
      module Runners
        module Flow
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def update_flow(tick_results: {}, **)
            challenge_input = extract_challenge(tick_results)
            skill_input = extract_skill(tick_results)
            modifiers = extract_modifiers(tick_results)

            flow_detector.update(challenge_input: challenge_input, skill_input: skill_input, modifiers: modifiers)

            breakers = detect_flow_breakers(tick_results)
            if breakers.any? && flow_detector.in_flow?
              flow_detector.instance_variable_set(:@flow_state, :disrupted)
              flow_detector.instance_variable_set(:@consecutive_flow_ticks, 0)
            end

            Legion::Logging.debug "[flow] state=#{flow_detector.flow_state} score=#{flow_detector.flow_score.round(3)} " \
                                  "deep=#{flow_detector.deep_flow?} breakers=#{breakers}"

            {
              state:     flow_detector.flow_state,
              score:     flow_detector.flow_score.round(3),
              in_flow:   flow_detector.in_flow?,
              deep_flow: flow_detector.deep_flow?,
              effects:   flow_detector.flow_effects,
              breakers:  breakers,
              challenge: flow_detector.challenge.round(3),
              skill:     flow_detector.skill.round(3)
            }
          end

          def flow_status(**)
            Legion::Logging.debug "[flow] status: state=#{flow_detector.flow_state} score=#{flow_detector.flow_score.round(3)}"
            flow_detector.to_h
          end

          def flow_effects(**)
            effects = flow_detector.flow_effects
            Legion::Logging.debug "[flow] effects: #{effects}"
            { effects: effects, in_flow: flow_detector.in_flow?, deep_flow: flow_detector.deep_flow? }
          end

          def flow_history(limit: 20, **)
            recent = flow_detector.history.last(limit)
            Legion::Logging.debug "[flow] history: #{recent.size} entries"
            { history: recent, total: flow_detector.history.size }
          end

          def flow_stats(**)
            Legion::Logging.debug '[flow] stats'
            {
              state:                  flow_detector.flow_state,
              score:                  flow_detector.flow_score.round(3),
              consecutive_flow_ticks: flow_detector.consecutive_flow_ticks,
              total_flow_ticks:       flow_detector.total_flow_ticks,
              flow_percentage:        flow_detector.flow_percentage,
              trend:                  flow_detector.flow_trend,
              balance:                flow_detector.challenge_skill_balance.round(3)
            }
          end

          private

          def flow_detector
            @flow_detector ||= Helpers::FlowDetector.new
          end

          def extract_challenge(tick_results)
            prediction_accuracy = tick_results.dig(:prediction_engine, :rolling_accuracy) || 0.5
            error_rate = tick_results.dig(:prediction_engine, :error_rate) || 0.5
            task_complexity = tick_results.dig(:action_selection, :complexity) || 0.5

            ((1.0 - prediction_accuracy) * 0.4) + (error_rate * 0.3) + (task_complexity * 0.3)
          end

          def extract_skill(tick_results)
            prediction_accuracy = tick_results.dig(:prediction_engine, :rolling_accuracy) || 0.5
            memory_strength = tick_results.dig(:memory_retrieval, :avg_strength) || 0.5
            habit_automation = tick_results.dig(:habit, :automation_level) || 0.5

            (prediction_accuracy * 0.4) + (memory_strength * 0.3) + (habit_automation * 0.3)
          end

          def extract_modifiers(tick_results)
            {
              curiosity_active: (tick_results.dig(:curiosity, :intensity) || 0.0) > 0.5,
              low_errors:       (tick_results.dig(:prediction_engine, :error_rate) || 1.0) < 0.2
            }
          end

          def detect_flow_breakers(tick_results)
            breakers = []
            check_anxiety_breaker(tick_results, breakers)
            check_simple_breakers(tick_results, breakers)
            check_conflict_breaker(tick_results, breakers)
            breakers
          end

          def check_anxiety_breaker(tick_results, breakers)
            anxiety = tick_results.dig(:emotional_evaluation, :anxiety) || 0.0
            breakers << :high_anxiety if anxiety > 0.8
          end

          def check_simple_breakers(tick_results, breakers)
            breakers << :trust_violation if tick_results.dig(:trust, :violation)
            breakers << :critical_error if tick_results.dig(:error, :critical)
            breakers << :burnout if tick_results.dig(:fatigue, :burnout)
          end

          def check_conflict_breaker(tick_results, breakers)
            conflict = tick_results.dig(:conflict, :severity)
            breakers << :conflict_escalation if conflict && conflict >= 4
          end
        end
      end
    end
  end
end
