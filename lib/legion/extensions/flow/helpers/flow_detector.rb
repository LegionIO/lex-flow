# frozen_string_literal: true

module Legion
  module Extensions
    module Flow
      module Helpers
        class FlowDetector
          attr_reader :challenge, :skill, :flow_state, :flow_score,
                      :consecutive_flow_ticks, :total_flow_ticks, :history

          def initialize
            @challenge = 0.5
            @skill = 0.5
            @flow_state = :relaxation
            @flow_score = 0.0
            @consecutive_flow_ticks = 0
            @total_flow_ticks = 0
            @history = []
          end

          def update(challenge_input:, skill_input:, modifiers: {})
            @challenge = ema(@challenge, challenge_input.clamp(0.0, 1.0), Constants::FLOW_ALPHA)
            @skill = ema(@skill, skill_input.clamp(0.0, 1.0), Constants::FLOW_ALPHA)

            @flow_state = classify_state
            @flow_score = compute_flow_score(modifiers)

            if @flow_state == :flow
              @consecutive_flow_ticks += 1
              @total_flow_ticks += 1
            else
              @consecutive_flow_ticks = 0
            end

            record_snapshot
          end

          def in_flow?
            @flow_state == :flow
          end

          def deep_flow?
            in_flow? && @consecutive_flow_ticks >= Constants::DEEP_FLOW_THRESHOLD
          end

          def flow_effects
            if in_flow?
              effects = Constants::FLOW_EFFECTS.dup
              if deep_flow?
                effects[:performance_boost] += 0.05
                effects[:creativity_boost] += 0.1
              end
              effects
            else
              { fatigue_reduction: 1.0, time_dilation: 1.0, performance_boost: 1.0,
                attention_broadening: 1.0, creativity_boost: 1.0 }
            end
          end

          def challenge_skill_balance
            (@challenge - @skill).abs
          end

          def flow_trend
            return :insufficient_data if @history.size < 5

            recent = @history.last(10)
            scores = recent.map { |h| h[:flow_score] }
            first_half = scores[0...(scores.size / 2)]
            second_half = scores[(scores.size / 2)..]
            diff = (second_half.sum / second_half.size.to_f) - (first_half.sum / first_half.size.to_f)

            if diff > 0.05
              :entering_flow
            elsif diff < -0.05
              :leaving_flow
            else
              :stable
            end
          end

          def flow_percentage
            return 0.0 if @history.empty?

            flow_count = @history.count { |h| h[:state] == :flow }
            (flow_count.to_f / @history.size * 100).round(1)
          end

          def to_h
            {
              state:                  @flow_state,
              score:                  @flow_score.round(3),
              challenge:              @challenge.round(3),
              skill:                  @skill.round(3),
              balance:                challenge_skill_balance.round(3),
              in_flow:                in_flow?,
              deep_flow:              deep_flow?,
              consecutive_flow_ticks: @consecutive_flow_ticks,
              total_flow_ticks:       @total_flow_ticks,
              flow_percentage:        flow_percentage,
              trend:                  flow_trend,
              effects:                flow_effects
            }
          end

          private

          def classify_state
            best_state = :apathy
            best_score = -1.0

            Constants::STATE_REGIONS.each do |state, region|
              next unless region[:challenge].cover?(@challenge) && region[:skill].cover?(@skill)

              score = region[:balanced] ? balance_bonus : 0.5
              if score > best_score
                best_score = score
                best_state = state
              end
            end

            best_state
          end

          def balance_bonus
            balance = challenge_skill_balance
            balance <= Constants::FLOW_ZONE[:balance_tolerance] ? 1.0 : 0.7
          end

          def compute_flow_score(modifiers)
            base = if in_flow?
                     0.7 + ((1.0 - challenge_skill_balance) * 0.3)
                   else
                     [0.0, 0.5 - (challenge_skill_balance * 0.5)].max
                   end

            base += Constants::DEEP_FLOW_BONUS if deep_flow?
            base += Constants::CURIOSITY_BONUS if modifiers[:curiosity_active]
            base += Constants::LOW_ERROR_BONUS if modifiers[:low_errors]

            base.clamp(0.0, 1.0)
          end

          def ema(current, observed, alpha)
            (current * (1.0 - alpha)) + (observed * alpha)
          end

          def record_snapshot
            @history << {
              state:      @flow_state,
              flow_score: @flow_score,
              challenge:  @challenge,
              skill:      @skill,
              at:         Time.now.utc
            }
            @history.shift while @history.size > Constants::MAX_FLOW_HISTORY
          end
        end
      end
    end
  end
end
