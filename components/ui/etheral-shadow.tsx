'use client';

import React, { useEffect, useId, useRef, type CSSProperties } from 'react';
import { animate, useMotionValue, type AnimationPlaybackControls } from 'framer-motion';
import { Orbit, Sparkles } from 'lucide-react';

interface ResponsiveImage {
  src: string;
  alt?: string;
  srcSet?: string;
}

interface AnimationConfig {
  preview?: boolean;
  scale: number;
  speed: number;
}

interface NoiseConfig {
  opacity: number;
  scale: number;
}

interface ShadowOverlayProps {
  type?: 'preset' | 'custom';
  presetIndex?: number;
  customImage?: ResponsiveImage;
  sizing?: 'fill' | 'stretch';
  color?: string;
  animation?: AnimationConfig;
  noise?: NoiseConfig;
  style?: CSSProperties;
  className?: string;
  title?: string;
  subtitle?: string;
}

function mapRange(
  value: number,
  fromLow: number,
  fromHigh: number,
  toLow: number,
  toHigh: number
): number {
  if (fromLow === fromHigh) {
    return toLow;
  }
  const percentage = (value - fromLow) / (fromHigh - fromLow);
  return toLow + percentage * (toHigh - toLow);
}

const useInstanceId = (): string => {
  const id = useId();
  const cleanId = id.replace(/:/g, '');
  return `shadowoverlay-${cleanId}`;
};

const ETHERVAP_BG =
  'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=2400&q=80';
const ETHERVAP_NOISE =
  'https://images.unsplash.com/photo-1550684376-efcbd6e3f031?auto=format&fit=crop&w=700&q=70';

export function Component({
  sizing = 'fill',
  color = 'rgba(236, 72, 153, 0.88)',
  animation,
  noise,
  style,
  className,
  title = 'EtherVap',
  subtitle = 'Liquid market for AI inference capacity'
}: ShadowOverlayProps) {
  const id = useInstanceId();
  const animationEnabled = Boolean(animation && animation.scale > 0);
  const feColorMatrixRef = useRef<SVGFEColorMatrixElement>(null);
  const hueRotateMotionValue = useMotionValue(180);
  const hueRotateAnimation = useRef<AnimationPlaybackControls | null>(null);

  const displacementScale = animation ? mapRange(animation.scale, 1, 100, 20, 100) : 0;
  const animationDuration = animation ? mapRange(animation.speed, 1, 100, 1000, 50) : 1;

  useEffect(() => {
    if (!feColorMatrixRef.current || !animationEnabled) {
      return;
    }

    hueRotateAnimation.current?.stop();
    hueRotateMotionValue.set(0);
    hueRotateAnimation.current = animate(hueRotateMotionValue, 360, {
      duration: animationDuration / 25,
      repeat: Infinity,
      repeatType: 'loop',
      ease: 'linear',
      onUpdate: (value: number) => {
        feColorMatrixRef.current?.setAttribute('values', String(value));
      }
    });

    return () => {
      hueRotateAnimation.current?.stop();
    };
  }, [animationEnabled, animationDuration, hueRotateMotionValue]);

  return (
    <div
      className={className}
      style={{
        overflow: 'hidden',
        position: 'relative',
        width: '100%',
        height: '100%',
        borderRadius: '1.5rem',
        border: '1px solid rgba(255,255,255,0.15)',
        ...style
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: -displacementScale,
          filter: animationEnabled ? `url(#${id}) blur(4px)` : 'none'
        }}
      >
        {animationEnabled && (
          <svg style={{ position: 'absolute' }}>
            <defs>
              <filter id={id}>
                <feTurbulence
                  result='undulation'
                  numOctaves='2'
                  baseFrequency={`${mapRange(animation.scale, 0, 100, 0.001, 0.0005)},${mapRange(animation.scale, 0, 100, 0.004, 0.002)}`}
                  seed='0'
                  type='turbulence'
                />
                <feColorMatrix ref={feColorMatrixRef} in='undulation' type='hueRotate' values='180' />
                <feColorMatrix
                  in='dist'
                  result='circulation'
                  type='matrix'
                  values='4 0 0 0 1  4 0 0 0 1  4 0 0 0 1  1 0 0 0 0'
                />
                <feDisplacementMap
                  in='SourceGraphic'
                  in2='circulation'
                  scale={displacementScale}
                  result='dist'
                />
                <feDisplacementMap
                  in='dist'
                  in2='undulation'
                  scale={displacementScale}
                  result='output'
                />
              </filter>
            </defs>
          </svg>
        )}

        <div
          style={{
            width: '100%',
            height: '100%',
            backgroundImage: `linear-gradient(145deg, rgba(10, 10, 10, 0.72), rgba(236, 72, 153, 0.20)), url(${ETHERVAP_BG})`,
            backgroundSize: sizing === 'stretch' ? '100% 100%' : 'cover',
            backgroundRepeat: 'no-repeat',
            backgroundPosition: 'center'
          }}
        />

        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: `radial-gradient(circle at 20% 20%, ${color}, rgba(17, 24, 39, 0.08) 60%)`,
            mixBlendMode: 'screen'
          }}
        />
      </div>

      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          width: 'min(90%, 840px)',
          transform: 'translate(-50%, -50%)',
          textAlign: 'center',
          zIndex: 10,
          color: '#f9fafb'
        }}
      >
        <div className='mx-auto mb-5 flex w-fit items-center gap-2 rounded-full border border-white/30 bg-black/30 px-4 py-2 backdrop-blur'>
          <Orbit className='h-4 w-4 text-pink-300' />
          <span className='text-xs font-semibold uppercase tracking-[0.16em] text-white/85'>
            EtherVap Edge Experience
          </span>
        </div>
        <h1 className='text-5xl font-extrabold tracking-tight text-white md:text-7xl lg:text-8xl'>
          {title}
        </h1>
        <p className='mx-auto mt-4 max-w-2xl text-base text-white/80 md:text-lg'>
          {subtitle}
        </p>
        <div className='mx-auto mt-8 flex w-fit items-center gap-2 rounded-xl border border-pink-300/40 bg-pink-500/20 px-4 py-2 text-sm text-pink-100'>
          <Sparkles className='h-4 w-4' />
          Premium gateway visuals with animated shadow field
        </div>
      </div>

      {noise && noise.opacity > 0 && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: `url(${ETHERVAP_NOISE})`,
            backgroundSize: `${noise.scale * 220}px`,
            backgroundRepeat: 'repeat',
            opacity: noise.opacity / 7,
            mixBlendMode: 'soft-light',
            pointerEvents: 'none'
          }}
        />
      )}
    </div>
  );
}
