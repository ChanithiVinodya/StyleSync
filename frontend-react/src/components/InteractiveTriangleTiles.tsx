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

    // Viewport mouse coordinates
    const mouse = {
      x: -2000,
      y: -2000,
      active: false,
    };

    // Smooth scroll position tracking
    let targetScrollY = typeof window !== 'undefined' ? window.scrollY : 0;
    let currentScrollY = targetScrollY;

    // Refined architectural geometry
    const SIDE = 62; // Equilateral triangle side length
    const TRI_HEIGHT = SIDE * (Math.sqrt(3) / 2); // ~53.69px
    const INFLUENCE_RADIUS = 165; // Proximity field around cursor
    const MAX_PULL = 6.5; // Delicate, organic follow pull (subtle & natural)
    const ELEVATION_SCALE = 0.024; // Subtle 2.4% elevation lift

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

    // Scroll listener for seamless parallax & tile alignment
    const handleScroll = () => {
      targetScrollY = window.scrollY;
    };
    window.addEventListener('scroll', handleScroll, { passive: true });

    // Track mouse position
    const handleMouseMove = (e: MouseEvent) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
      mouse.active = true;
    };

    const handleMouseLeave = () => {
      mouse.active = false;
      mouse.x = -2000;
      mouse.y = -2000;
    };

    // Touch support for mobile devices
    const handleTouchMove = (e: TouchEvent) => {
      if (e.touches.length > 0) {
        mouse.x = e.touches[0].clientX;
        mouse.y = e.touches[0].clientY;
        mouse.active = true;
      }
    };

    const handleTouchEnd = () => {
      mouse.active = false;
      mouse.x = -2000;
      mouse.y = -2000;
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

      // Smooth scroll interpolation (eases any browser scroll jumps)
      const scrollLerp = Math.min(1, 10 * dt);
      currentScrollY += (targetScrollY - currentScrollY) * scrollLerp;
      if (Math.abs(targetScrollY - currentScrollY) < 0.1) {
        currentScrollY = targetScrollY;
      }

      ctx.clearRect(0, 0, width, height);

      const isDark = themeRef.current === 'dark';
      const halfSide = SIDE / 2;

      // Calibrated subtle alpha baseline
      const baseAlpha = isDark ? 0.028 : 0.022;
      const hoverAlphaLift = isDark ? 0.085 : 0.07;

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
            const raw = 1 - distToMouse / INFLUENCE_RADIUS;
            // Smooth natural cubic easing curve
            const factor = raw * raw * (3 - 2 * raw);

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
            // Returning to rest
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
      const lerpSpeed = Math.min(1, 8.5 * dt);
      const keysToDelete: string[] = [];

      activeTiles.forEach((state, key) => {
        state.currentDx += (state.targetDx - state.currentDx) * lerpSpeed;
        state.currentDy += (state.targetDy - state.currentDy) * lerpSpeed;
        state.currentScale += (state.targetScale - state.currentScale) * lerpSpeed;
        state.currentAlpha += (state.targetAlpha - state.currentAlpha) * lerpSpeed;
        state.currentWarmth += (state.targetWarmth - state.currentWarmth) * lerpSpeed;

        if (
          state.targetWarmth === 0 &&
          Math.abs(state.currentDx) < 0.03 &&
          Math.abs(state.currentDy) < 0.03 &&
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

          // Delicate travertine fill
          if (isDark) {
            if (warmth > 0.02) {
              const goldR = Math.round(205 + (224 - 205) * warmth);
              const goldG = Math.round(165 + (160 - 165) * warmth);
              const goldB = Math.round(110 + (56 - 110) * warmth);
              ctx.fillStyle = `rgba(${goldR}, ${goldG}, ${goldB}, ${alpha * 1.15})`;
            } else {
              ctx.fillStyle = `rgba(165, 150, 135, ${alpha * 0.45})`;
            }
          } else {
            if (warmth > 0.02) {
              const goldR = Math.round(198 + (192 - 198) * warmth);
              const goldG = Math.round(175 + (134 - 175) * warmth);
              const goldB = Math.round(138 + (50 - 138) * warmth);
              ctx.fillStyle = `rgba(${goldR}, ${goldG}, ${goldB}, ${alpha * 0.9})`;
            } else {
              ctx.fillStyle = `rgba(195, 185, 170, ${alpha})`;
            }
          }
          ctx.fill();

          // Subtle hairline grout perimeter
          if (isDark) {
            if (warmth > 0.05) {
              ctx.strokeStyle = `rgba(229, 168, 62, ${Math.min(0.26, alpha * 2.2)})`;
              ctx.lineWidth = 0.75;
            } else {
              ctx.strokeStyle = `rgba(145, 130, 115, ${Math.min(0.08, alpha * 1.5)})`;
              ctx.lineWidth = 0.55;
            }
          } else {
            if (warmth > 0.05) {
              ctx.strokeStyle = `rgba(196, 138, 54, ${Math.min(0.22, alpha * 2.0)})`;
              ctx.lineWidth = 0.7;
            } else {
              ctx.strokeStyle = `rgba(195, 185, 172, ${Math.min(0.10, alpha * 1.8)})`;
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
      window.removeEventListener('scroll', handleScroll);
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
        className="w-full h-full block opacity-90 transition-opacity duration-700"
      />
    </div>
  );
};
