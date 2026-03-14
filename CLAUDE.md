# lex-flow

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Flow state modeling for the LegionIO cognitive architecture. Implements Csikszentmihalyi's flow theory — the state of optimal experience characterized by complete absorption in a challenging task. Monitors the challenge-skill balance (the primary flow precondition), tracks flow entry/exit transitions, and computes performance enhancement during flow. Enables the agent to recognize when it is in a flow state and to optimize task assignment to maintain it.

## Gem Info

- **Gem name**: `lex-flow`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Flow`
- **Location**: `extensions-agentic/lex-flow/`

## File Structure

```
lib/legion/extensions/flow/
  flow.rb                       # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # FLOW_STATES, CHANNEL_LABELS, PERFORMANCE_BOOST, thresholds
    flow_session.rb             # FlowSession value object
    flow_engine.rb              # Engine: challenge-skill tracking, state transitions, performance
  runners/
    flow.rb                     # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `FLOW_ZONE_LOW` | 0.4 | Lower bound of challenge-skill balance for flow entry |
| `FLOW_ZONE_HIGH` | 0.6 | Upper bound of challenge-skill balance for flow entry |
| `FLOW_ENTRY_DURATION` | 3 | Consecutive ticks in balance zone required to enter flow |
| `FLOW_EXIT_THRESHOLD` | 0.15 | Challenge-skill imbalance that breaks flow |
| `PERFORMANCE_BOOST` | 0.3 | Performance factor bonus during active flow |
| `SKILL_LEARNING_RATE` | 0.02 | Skill increases per successful task tick |
| `FLOW_DECAY` | 0.05 | Flow intensity decays per tick without reinforcement |
| `MAX_SESSIONS` | 100 | Flow session history cap |
| `FLOW_STATES` | `[:no_flow, :approaching, :flow, :peak_flow, :exiting]` | State machine values |
| `CHANNEL_LABELS` | hash | Csikszentmihalyi channel names: `anxiety / arousal / flow / control / boredom / relaxation / apathy / worry` |

## Runners

All methods in `Legion::Extensions::Flow::Runners::Flow`.

| Method | Key Args | Returns |
|---|---|---|
| `update_challenge_skill` | `challenge: 0.5, skill: 0.5, domain: nil` | `{ success:, balance:, channel:, flow_state:, in_flow: }` |
| `flow_status` | — | `{ success:, flow_state:, flow_intensity:, in_flow:, performance_boost:, session_duration: }` |
| `performance_modifier` | — | `{ success:, modifier:, flow_state:, base_modifier: 1.0 }` |
| `enter_flow` | `domain: nil` | `{ success:, entered:, flow_state:, session_id: }` |
| `exit_flow` | `reason: nil` | `{ success:, exited:, session_duration:, peak_intensity: }` |
| `challenge_skill_balance` | — | `{ success:, challenge:, skill:, balance:, channel_label: }` |
| `optimal_challenge` | `skill: nil` | `{ success:, optimal_challenge:, current_skill:, recommendation: }` |
| `flow_history` | `limit: 10` | `{ success:, sessions:, count:, avg_duration: }` |
| `update_flow` | — | `{ success:, flow_intensity:, state_changed:, new_state: }` (decay flow intensity) |
| `flow_stats` | — | Full stats hash including total flow time, peak sessions |

## Helpers

### `FlowSession`
Records a flow episode. Attributes: `id`, `domain`, `start_time`, `end_time`, `duration`, `peak_intensity`, `reason_exited`, `challenge_at_entry`, `skill_at_entry`. `to_h`.

### `FlowEngine`
Central state: `@challenge` (float 0–1), `@skill` (float 0–1), `@flow_state`, `@flow_intensity`, `@consecutive_balance_ticks`, `@sessions` (array). Key methods:
- `update(challenge:, skill:, domain:)`: computes balance = `1.0 - |challenge - skill|`, maps to Csikszentmihalyi channel, advances flow state machine
- `state_machine_tick(balance:)`: increments `@consecutive_balance_ticks` when in balance zone, enters `:approaching` at 1 tick, `:flow` at `FLOW_ENTRY_DURATION`, exits flow when imbalance > `FLOW_EXIT_THRESHOLD`
- `channel_for(challenge:, skill:)`: maps the 2D challenge-skill space to the 8 Csikszentmihalyi channels
- `performance_modifier`: returns `1.0 + PERFORMANCE_BOOST` when in flow, scales with intensity
- `decay_intensity`: reduces `@flow_intensity` per tick when not receiving challenge-skill updates

## Integration Points

- `update_challenge_skill` called from lex-tick with current task complexity as `challenge` and agent capability as `skill`
- `performance_modifier` scales lex-tick's timing budget (flow = faster, higher quality processing)
- `flow_status[:in_flow]` feeds lex-emotion as a strong positive valence signal (flow = joy)
- `optimal_challenge` recommendation feeds lex-swarm's task assignment (route tasks that match skill level)
- `flow_status[:flow_intensity]` modulates lex-fatigue's decay rate (flow reduces fatigue accumulation)

## Development Notes

- Challenge-skill balance = `1.0 - |challenge - skill|`: perfect balance (equal values) = 1.0, not a ratio
- Flow entry requires consecutive ticks in the balance zone — single-tick spikes do not trigger flow
- Csikszentmihalyi channel assignment uses 2D region mapping (challenge > 0.5 and skill > 0.5 = flow/arousal/control region)
- Flow intensity decays when `update_challenge_skill` is not called (idle = flow degradation)
- `SKILL_LEARNING_RATE` increases `@skill` each tick while in flow (mastery grows during flow states)
