# MMM Home Flatlay v1

## Decision

Home changes from an avatar-centric introduction to a wardrobe-centric styling
dashboard. Its primary question is: “What are we wearing today?”

## Contract

- Today's Look displays the exact `Outfit.itemIds` selected by the user.
- Actual wardrobe images form a deterministic flatlay on a neutral canvas.
- Avatar rendering remains available elsewhere in the product but is not a
  Home dependency or release blocker.
- Existing outfit generation, rush, repetition, routes, and persistence stay
  canonical.
- Weather and occasion appear only when supported by real presentation state.
