# Vertical Slice 0.1

## Goal

Build one playable arcade hockey match that proves the core feel of Puck King Hockey.

The player should be able to load into a test rink, skate, fight for the puck, shoot, check opponents, score goals, and finish a first-to-3 match.

## Success Criteria

The vertical slice is successful when:

- Movement feels responsive and fun.
- The puck is readable and controllable.
- Shooting feels satisfying.
- Checking creates funny, useful chaos.
- Goals trigger clear feedback and reset properly.
- Basic AI can participate without feeling completely broken.
- A match can end in a win or loss.
- The player sees a simple post-match reward choice.

## Required Scenes

- Main menu
- Test rink
- Match HUD
- Win/loss screen
- Reward draft screen

## Required Systems

### Skating

- Acceleration
- Friction
- Turning
- Hard skate/boost
- Wall collision handling

### Puck

- Loose puck movement
- Possession pickup radius
- Possession release
- Shot velocity
- Basic bounce handling

### Shooting

- Tap shot
- Charged shot if time allows
- Directional aiming
- Goal detection

### Checking

- Check input
- Hitbox/timing window
- Knockback
- Stun/knockdown placeholder
- Puck loss on hit

### AI

- Chase loose puck
- Attack puck carrier
- Shoot near net
- Defend near own goal

### Match Flow

- Spawn teams
- Start match
- Score goal
- Reset after goal
- First to 3 wins
- Show result screen

### Reward Draft

- Show 3 upgrade cards
- Select one
- Apply upgrade placeholder

## Out of Scope For 0.1

- Online multiplayer
- Full season mode
- Full character creator
- Real hockey penalties
- Complex goalie logic
- Advanced roster management
- Save system
- Steam integration
- Console support

## Development Order

1. Project setup
2. Test rink
3. Player controller
4. Puck possession
5. Shooting/scoring
6. Checking
7. Basic AI
8. Match end screen
9. Reward draft
10. First tuning pass

## Tuning Principle

Start exaggerated. Arcade hockey should feel big, readable, and slightly ridiculous. We can reduce chaos later if needed.
