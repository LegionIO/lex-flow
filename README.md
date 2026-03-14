# lex-flow

Flow state modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Implements Csikszentmihalyi's flow theory — the state of optimal experience from complete absorption in a challenging task. Monitors the challenge-skill balance (the primary condition for flow entry), tracks flow state transitions, computes a performance boost during active flow, and records flow session history. Enables the agent to recognize when it is in flow and to receive optimally challenging tasks to sustain it.

## Usage

```ruby
client = Legion::Extensions::Flow::Client.new

# Update challenge-skill balance each tick
client.update_challenge_skill(challenge: 0.65, skill: 0.60, domain: :coding)
# => { success: true, balance: 0.95, channel: :flow, flow_state: :approaching, in_flow: false }

# After sufficient consecutive ticks in balance zone, flow is entered
client.update_challenge_skill(challenge: 0.65, skill: 0.60, domain: :coding)
client.update_challenge_skill(challenge: 0.65, skill: 0.60, domain: :coding)
# => { flow_state: :flow, in_flow: true }

# Check current flow status
client.flow_status
# => { flow_state: :flow, flow_intensity: 0.8, in_flow: true,
#      performance_boost: 0.3, session_duration: 12 }

# Performance modifier during flow
client.performance_modifier
# => { modifier: 1.3, flow_state: :flow, base_modifier: 1.0 }

# Find the optimal challenge level for current skill
client.optimal_challenge(skill: 0.6)
# => { optimal_challenge: 0.6, current_skill: 0.6, recommendation: :maintain_current_difficulty }

# Flow session history
client.flow_history(limit: 5)
# => { sessions: [...], count: 5, avg_duration: 18 }

# Periodic tick: decay flow intensity if not sustained
client.update_flow
```

## Csikszentmihalyi Channels

Challenge-skill balance maps to 8 experiential channels (anxiety, arousal, flow, control, boredom, relaxation, apathy, worry). Flow occurs when both challenge and skill are high and approximately matched.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
