abstract final class AvatarRenderBridge {
  /// Fixed JavaScript only. Wardrobe state is passed as one JSON value by
  /// [GlbAvatarRenderer], never interpolated into this source.
  static const script = r'''
(() => {
  const viewer = document.querySelector('model-viewer#mmm-avatar');
  if (!viewer) return;

  const garmentTemplates = [
    'hat', 'regular_tee', 'fitted_top', 'oversized_top', 'shirt_blouse',
    'sweater_hoodie', 'jacket', 'blazer', 'coat', 'regular_pants',
    'slim_pants', 'wide_leg_pants', 'shorts', 'skirt', 'straight_dress',
    'a_line_dress', 'sneaker', 'dress_shoe', 'boot', 'bag', 'accessory'
  ];
  const materialCache = new Map();
  const textureCache = new Map();
  let lastLook = null;

  const send = (channel, value) => {
    const bridge = window[channel];
    if (bridge && typeof bridge.postMessage === 'function') {
      bridge.postMessage(JSON.stringify(value || {}));
    }
  };

  const validHex = (value, fallback) =>
    typeof value === 'string' && /^#[0-9a-fA-F]{6}$/.test(value)
      ? value
      : fallback;

  const hexToRgb = (value) => {
    const hex = validHex(value, '#D9DCE5').slice(1);
    return [0, 2, 4].map((offset) => parseInt(hex.slice(offset, offset + 2), 16) / 255);
  };

  const materialFor = (name) => {
    if (materialCache.has(name)) return materialCache.get(name);
    const material = viewer.model && typeof viewer.model.getMaterialByName === 'function'
      ? viewer.model.getMaterialByName(name)
      : viewer.model && viewer.model.materials
          ? viewer.model.materials.find((entry) => entry.name === name)
          : null;
    materialCache.set(name, material || null);
    return material || null;
  };

  const setMaterial = (material, color, opacity, roughness, metallic) => {
    if (!material) return;
    const pbr = material.pbrMetallicRoughness;
    if (!pbr) return;
    pbr.setBaseColorFactor([...hexToRgb(color), opacity]);
    pbr.setRoughnessFactor(Math.max(0, Math.min(1, Number(roughness) || 0.65)));
    pbr.setMetallicFactor(Math.max(0, Math.min(1, Number(metallic) || 0)));
    if (typeof material.setAlphaMode === 'function') {
      material.setAlphaMode(opacity < 0.99 ? 'BLEND' : 'OPAQUE');
    }
  };

  const contrastColor = (value) => {
    const rgb = hexToRgb(value);
    return (rgb[0] * 0.299 + rgb[1] * 0.587 + rgb[2] * 0.114) > 0.62
      ? '#4B5563'
      : '#F8FAFC';
  };

  const patternTexture = async (pattern, color) => {
    if (!pattern || pattern === 'solid' || typeof viewer.createCanvasTexture !== 'function') {
      return null;
    }
    const key = `${pattern}:${color}`;
    if (textureCache.has(key)) return textureCache.get(key);
    const texture = viewer.createCanvasTexture();
    const canvas = texture && texture.source && texture.source.element;
    const context = canvas && canvas.getContext && canvas.getContext('2d');
    if (!context) return null;
    canvas.width = 64;
    canvas.height = 64;
    const contrast = contrastColor(color);
    context.fillStyle = color;
    context.fillRect(0, 0, 64, 64);
    context.strokeStyle = contrast;
    context.fillStyle = contrast;
    context.lineWidth = 4;
    if (pattern === 'stripe') {
      for (let x = -64; x < 128; x += 18) {
        context.beginPath();
        context.moveTo(x, 0);
        context.lineTo(x + 64, 64);
        context.stroke();
      }
    } else if (pattern === 'plaid') {
      for (let x = 8; x < 64; x += 16) {
        context.fillRect(x, 0, 4, 64);
        context.fillRect(0, x, 64, 4);
      }
    } else if (pattern === 'graphic') {
      context.beginPath();
      context.arc(32, 32, 15, 0, Math.PI * 2);
      context.fill();
    } else {
      for (let x = 8; x < 64; x += 18) {
        for (let y = 8; y < 64; y += 18) {
          context.beginPath();
          context.arc(x, y, 3, 0, Math.PI * 2);
          context.fill();
        }
      }
    }
    texture.source.update();
    textureCache.set(key, texture);
    return texture;
  };

  const applyGarment = async (garment) => {
    if (!garment || !garment.template || !garmentTemplates.includes(garment.template)) return;
    const material = materialFor(`MMM_GARMENT__${garment.template}__base`);
    if (!material) return;
    const color = validHex(garment.color, '#D9DCE5');
    setMaterial(material, color, 1, garment.roughness, garment.metallic);
    const pbr = material.pbrMetallicRoughness;
    if (pbr && pbr.baseColorTexture) {
      const texture = await patternTexture(garment.pattern, color);
      pbr.baseColorTexture.setTexture(texture);
      if (texture) pbr.setBaseColorFactor([1, 1, 1, 1]);
    }
  };

  const playAnimation = (look) => {
    const reduced = Boolean(look && look.reduceMotion);
    if (reduced) {
      viewer.timeScale = 0;
      viewer.pause();
      return;
    }
    viewer.timeScale = 1;
    const animation = look && ['idle', 'blink', 'wave', 'look', 'outfit_reveal'].includes(look.animation)
      ? look.animation
      : 'idle';
    viewer.animationName = animation;
    if (animation === 'idle') viewer.play();
    else viewer.play({ repetitions: 1 });
  };

  const applyLook = async (look) => {
    lastLook = look || {};
    if (!viewer.model) return;
    materialCache.clear();
    const skinTones = ['#F5E6D3', '#E8C4A0', '#C89B6E', '#B07840', '#9A6235', '#8B5A2B', '#4A2F1A'];
    const hairColors = ['#12090A', '#2C1810', '#6B3A2A', '#C9A96E', '#8B3A1C', '#D4CFC8'];
    const skin = skinTones[Math.max(0, Math.min(6, Number(look.skinToneIndex) || 0))];
    const hair = hairColors[Math.max(0, Math.min(5, Number(look.hairColorIndex) || 0))];
    setMaterial(materialFor('MMM_BODY__skin'), skin, 1, 0.48, 0);
    const style = Math.max(0, Math.min(5, Number(look.hairStyleIndex) || 0));
    for (let index = 0; index < 6; index += 1) {
      setMaterial(materialFor(`MMM_HAIR__style_${index}__base`), hair, index === style ? 1 : 0, 0.48, 0);
    }
    for (const template of garmentTemplates) {
      setMaterial(materialFor(`MMM_GARMENT__${template}__base`), '#D9DCE5', 0, 0.65, 0);
    }
    const garments = Array.isArray(lastLook.garments) ? lastLook.garments : [];
    const visibleGarments = lastLook.hasSelectedOutfit
      ? garments
      : [
          { template: 'regular_tee', color: '#D9DCE5', pattern: 'solid' },
          { template: 'regular_pants', color: '#B8C2D6', pattern: 'solid' },
          { template: 'sneaker', color: '#F3F4F6', pattern: 'solid' }
        ];
    await Promise.all(visibleGarments.map(applyGarment));
    playAnimation(lastLook);
  };

  window.mmmAvatar = window.mmmAvatar || {};
  window.mmmAvatar.applyLook = applyLook;
  viewer.addEventListener('load', () => {
    send('MMMAvatarReady', { animations: viewer.availableAnimations || [] });
    if (lastLook) applyLook(lastLook);
  });
  viewer.addEventListener('error', () => send('MMMAvatarError', { reason: 'model_load_failed' }));
  viewer.addEventListener('pointerup', (event) => {
    if (!viewer.model || typeof viewer.materialFromPoint !== 'function') return;
    const material = viewer.materialFromPoint(event.offsetX, event.offsetY);
    if (material && material.name) send('MMMAvatarMaterialTap', { material: material.name });
  });
})();
''';
}
