ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS body_shape       TEXT    NOT NULL DEFAULT 'female',
  ADD COLUMN IF NOT EXISTS skin_tone_index  INTEGER NOT NULL DEFAULT 1
    CHECK (skin_tone_index BETWEEN 0 AND 6),
  ADD COLUMN IF NOT EXISTS hair_color_index INTEGER NOT NULL DEFAULT 1
    CHECK (hair_color_index BETWEEN 0 AND 5),
  ADD COLUMN IF NOT EXISTS hair_style_index INTEGER NOT NULL DEFAULT 3
    CHECK (hair_style_index BETWEEN 0 AND 5);
