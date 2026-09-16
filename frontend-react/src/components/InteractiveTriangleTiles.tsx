import React, { useEffect, useRef } from 'react';
import { useTheme } from '../context/ThemeContext';

interface ActiveTileState {
  currentDx: number;
  currentDy: number;
  currentScale: number;
  currentAlpha: number;
  currentWarmth: number;
  targetDx: number;
  targetDy: number;
  targetScale: number;
  targetAlpha: number;
  targetWarmth: number;
}

export const InteractiveTriangleTiles: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const { theme } = useTheme();
  const themeRef = useRef(theme);

  // Keep themeRef updated synchronously
  useEffect(() => {
    themeRef.current = theme;
  }, [theme]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d', { alpha: true });
    if (!ctx) return;

    let animationFrameId: number;
    let width = 0;
    let height = 0;
    let dpr = 1;

    // Viewport mouse coordinates with smooth organic damping
    const mouse = {
      x: -2000,
      y: -2000,
      targetX: -2000,
      targetY: -2000,
      active: false,
    };

    // Refined architectural geometry
    const SIDE = 62; // Equilateral triangle side length
    const TRI_HEIGHT = SIDE * (Math.sqrt(3) / 2); // ~53.69px
    const INFLUENCE_RADIUS = 180; // Gentle proximity field around cursor
    const MAX_PULL = 7.0; // Natural magnetic follow
    const ELEVATION_SCALE = 0.025; // Delicate elevation lift

    // Active state map for excited tiles (pruned automatically when tiles settle)
    const activeTiles = new Map<string, ActiveTileState>();

    // Resize handler
    const handleResize = () => {
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.scale(dpr, dpr);
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    // Track mouse position with smooth transitions
    const handleMouseMove = (e: MouseEvent) => {
      mouse.targetX = e.clientX;
      mouse.targetY = e.clientY;
      if (!mouse.active) {
        mouse.x = e.clientX;
        mouse.y = e.clientY;
      }
      mouse.active = true;
    };

    const handleMouseLeave = () => {
      mouse.active = false;
      mouse.targetX = -2000;
      mouse.targetY = -2000;
    };

    // Touch support for mobile devices
    const handleTouchMove = (e: TouchEvent) => {
      if (e.touches.length > 0) {
        mouse.targetX = e.touches[0].clientX;
        mouse.targetY = e.touches[0].clientY;
        if (!mouse.active) {
          mouse.x = e.touches[0].clientX;
          mouse.y = e.touches[0].clientY;
        }
        mouse.active = true;
      }
    };

    const handleTouchEnd = () => {
      mouse.active = false;
      mouse.targetX = -2000;
      mouse.targetY = -2000;
    };

    window.addEventListener('mousemove', handleMouseMove, { passive: true });
    window.addEventListener('mouseleave', handleMouseLeave);
    window.addEventListener('touchmove', handleTouchMove, { passive: true });
    window.addEventListener('touchend', handleTouchEnd);

    // Main render loop
    let lastTime = performance.now();

    const render = (now: number) => {
      const dt = Math.min((now - lastTime) / 1000, 0.064);
      lastTime = now;

      // Direct synchronous scroll tracking to eliminate any parallax lag or scroll stutter
      const currentScrollY = window.scrollY || window.pageYOffset || 0;

      // Organic mouse position interpolation for fluid tracking
      if (mouse.active) {
        const mouseSpeed = Math.min(1, 22 * dt);
        mouse.x += (mouse.targetX - mouse.x) * mouseSpeed;
        mouse.y += (mouse.targetY - mouse.y) * mouseSpeed;
      } else {
        mouse.x = -2000;
        mouse.y = -2000;
      }

      ctx.clearRect(0, 0, width, height);

      const isDark = themeRef.current === 'dark';
      const halfSide = SIDE / 2;

      // Calibrated subtle alpha baseline - lighter and delicate
      const baseAlpha = isDark ? 0.024 : 0.034;
      const hoverAlphaLift = isDark ? 0.080 : 0.095;

      // Determine visible rows in world-space
      const startRow = Math.floor((currentScrollY - TRI_HEIGHT * 2) / TRI_HEIGHT) - 1;
      const endRow = Math.ceil((currentScrollY + height + TRI_HEIGHT * 2) / TRI_HEIGHT) + 1;
      const cols = Math.ceil(width / halfSide) + 3;

      // 1. Evaluate cursor proximity across visible viewport tiles
      for (let r = startRow; r <= endRow; r++) {
        for (let c = -2; c <= cols; c++) {
          const isUpward = ((c + r) % 2 + 2) % 2 === 0;
          const baseCx = (c + 1) * halfSide;
          const baseWorldCy = (r + (isUpward ? 2 / 3 : 1 / 3)) * TRI_HEIGHT;
          const screenCy = baseWorldCy - currentScrollY;

          // Quick bounding box check against screen
          if (
            baseCx < -SIDE ||
            baseCx > width + SIDE ||
            screenCy < -TRI_HEIGHT ||
            screenCy > height + TRI_HEIGHT
          ) {
            continue;
          }

          const key = `${c}_${r}`;
          const distToMouse = mouse.active
            ? Math.hypot(mouse.x - baseCx, mouse.y - screenCy)
            : 9999;

          if (distToMouse < INFLUENCE_RADIUS) {
            const normDist = distToMouse / INFLUENCE_RADIUS;
            // Smooth cosine bell curve for natural, organic falloff
            const factor = Math.cos(normDist * Math.PI * 0.5) ** 2;

            const angle = Math.atan2(mouse.y - screenCy, mouse.x - baseCx);
            const targetDx = Math.cos(angle) * (factor * MAX_PULL);
            const targetDy = Math.sin(angle) * (factor * MAX_PULL);
            const targetScale = 1 + factor * ELEVATION_SCALE;
            const targetAlpha = baseAlpha + factor * hoverAlphaLift;
            const targetWarmth = factor;

            let state = activeTiles.get(key);
            if (!state) {
              state = {
                currentDx: 0,
                currentDy: 0,
                currentScale: 1,
                currentAlpha: baseAlpha,
                currentWarmth: 0,
                targetDx,
                targetDy,
                targetScale,
                targetAlpha,
                targetWarmth,
              };
              activeTiles.set(key, state);
            } else {
              state.targetDx = targetDx;
              state.targetDy = targetDy;
              state.targetScale = targetScale;
              state.targetAlpha = targetAlpha;
              state.targetWarmth = targetWarmth;
            }
          } else if (activeTiles.has(key)) {
            // Returning gracefully to rest
            const state = activeTiles.get(key)!;
            state.targetDx = 0;
            state.targetDy = 0;
            state.targetScale = 1;
            state.targetAlpha = baseAlpha;
            state.targetWarmth = 0;
          }
        }
      }

      // 2. Interpolate active tiles and prune settled ones
      const keysToDelete: string[] = [];

      activeTiles.forEach((state, key) => {
        // Dynamic spring lerp: faster follow when attracted, gentle settle when leaving
        const isAttracted = state.targetWarmth > 0;
        const lerpSpeed = Math.min(1, (isAttracted ? 12 : 6.5) * dt);

        state.currentDx += (state.targetDx - state.currentDx) * lerpSpeed;
        state.currentDy += (state.targetDy - state.currentDy) * lerpSpeed;
        state.currentScale += (state.targetScale - state.currentScale) * lerpSpeed;
        state.currentAlpha += (state.targetAlpha - state.currentAlpha) * lerpSpeed;
        state.currentWarmth += (state.targetWarmth - state.currentWarmth) * lerpSpeed;

        if (
          state.targetWarmth === 0 &&
          Math.abs(state.currentDx) < 0.02 &&
          Math.abs(state.currentDy) < 0.02 &&
          state.currentWarmth < 0.01 &&
          Math.abs(state.currentAlpha - baseAlpha) < 0.002
        ) {
          keysToDelete.push(key);
        }
      });

      for (let i = 0; i < keysToDelete.length; i++) {
        activeTiles.delete(keysToDelete[i]);
      }

      // 3. Render visible triangular tiles
      for (let r = startRow; r <= endRow; r++) {
        for (let c = -2; c <= cols; c++) {
          const isUpward = ((c + r) % 2 + 2) % 2 === 0;
          const baseCx = (c + 1) * halfSide;
          const baseWorldCy = (r + (isUpward ? 2 / 3 : 1 / 3)) * TRI_HEIGHT;
          const screenCy = baseWorldCy - currentScrollY;

          const key = `${c}_${r}`;
          const active = activeTiles.get(key);

          const renderCx = baseCx + (active ? active.currentDx : 0);
          const renderCy = screenCy + (active ? active.currentDy : 0);
          const scale = active ? active.currentScale : 1;
          const alpha = active ? active.currentAlpha : baseAlpha;
          const warmth = active ? active.currentWarmth : 0;

          // Frustum culling with generous margin for scaling/displacement
          if (
            renderCx < -SIDE * 1.2 ||
            renderCx > width + SIDE * 1.2 ||
            renderCy < -TRI_HEIGHT * 1.2 ||
            renderCy > height + TRI_HEIGHT * 1.2
          ) {
            continue;
          }

          ctx.save();
          ctx.translate(renderCx, renderCy);
          if (scale !== 1) {
            ctx.scale(scale, scale);
          }

          // Build equilateral triangle contour
          ctx.beginPath();
          if (isUpward) {
            ctx.moveTo(0, -(2 / 3) * TRI_HEIGHT);
            ctx.lineTo(halfSide, (1 / 3) * TRI_HEIGHT);
            ctx.lineTo(-halfSide, (1 / 3) * TRI_HEIGHT);
          } else {
            ctx.moveTo(-halfSide, -(1 / 3) * TRI_HEIGHT);
            ctx.lineTo(halfSide, -(1 / 3) * TRI_HEIGHT);
            ctx.lineTo(0, (2 / 3) * TRI_HEIGHT);
          }
          ctx.closePath();

          // Delicate travertine fill - soft, luminous & lighter
          if (isDark) {
            if (warmth > 0.02) {
              const goldR = Math.round(205 + (224 - 205) * warmth);
              const goldG = Math.round(165 + (160 - 165) * warmth);
              const goldB = Math.round(110 + (56 - 110) * warmth);
              ctx.fillStyle = `rgba(${goldR}, ${goldG}, ${goldB}, ${alpha * 1.15})`;
            } else {
              ctx.fillStyle = `rgba(165, 150, 135, ${alpha * 0.40})`;
            }
          } else {
            if (warmth > 0.02) {
              const goldR = Math.round(202 + (192 - 202) * warmth);
              const goldG = Math.round(170 + (134 - 170) * warmth);
              const goldB = Math.round(128 + (50 - 128) * warmth);
              ctx.fillStyle = `rgba(${goldR}, ${goldG}, ${goldB}, ${alpha * 0.95})`;
            } else {
              ctx.fillStyle = `rgba(200, 192, 180, ${alpha * 0.55})`;
            }
          }
          ctx.fill();

          // Subtle hairline grout perimeter
          if (isDark) {
            if (warmth > 0.05) {
              ctx.strokeStyle = `rgba(229, 168, 62, ${Math.min(0.26, alpha * 2.2)})`;
              ctx.lineWidth = 0.75;
            } else {
              ctx.strokeStyle = `rgba(145, 130, 115, ${Math.min(0.07, alpha * 1.4)})`;
              ctx.lineWidth = 0.55;
            }
          } else {
            if (warmth > 0.05) {
              ctx.strokeStyle = `rgba(196, 138, 54, ${Math.min(0.32, alpha * 2.2)})`;
              ctx.lineWidth = 0.75;
            } else {
              ctx.strokeStyle = `rgba(182, 172, 156, ${Math.min(0.12, alpha * 1.8)})`;
              ctx.lineWidth = 0.55;
            }
          }
          ctx.stroke();

          ctx.restore();
        }
      }

      animationFrameId = requestAnimationFrame(render);
    };

    animationFrameId = requestAnimationFrame(render);

    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseleave', handleMouseLeave);
      window.removeEventListener('touchmove', handleTouchMove);
      window.removeEventListener('touchend', handleTouchEnd);
    };
  }, []);

  return (
    <div
      className="fixed inset-0 pointer-events-none overflow-hidden z-0"
      aria-hidden="true"
    >
      <canvas
        ref={canvasRef}
        className="w-full h-full block opacity-100 transition-opacity duration-700"
      />
    </div>
  );
};
