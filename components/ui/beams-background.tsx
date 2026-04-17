"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { motion } from "motion/react";

interface BeamsBackgroundProps {
  className?: string;
  children?: ReactNode;
  intensity?: "subtle" | "medium" | "strong";
}

interface Beam {
  x: number;
  y: number;
  width: number;
  length: number;
  angle: number;
  speed: number;
  opacity: number;
  hue: number;
  pulse: number;
  pulseSpeed: number;
}

function cn(...classes: Array<string | undefined>): string {
  return classes.filter(Boolean).join(" ");
}

function createBeam(width: number, height: number): Beam {
  const angle = -34 + Math.random() * 8;
  return {
    x: Math.random() * width * 1.5 - width * 0.25,
    y: Math.random() * height * 1.5 - height * 0.25,
    width: 28 + Math.random() * 52,
    length: height * 2.4,
    angle,
    speed: 0.55 + Math.random() * 1.05,
    opacity: 0.14 + Math.random() * 0.18,
    // Hero palette: pink range.
    hue: 324 + Math.random() * 22,
    pulse: Math.random() * Math.PI * 2,
    pulseSpeed: 0.018 + Math.random() * 0.028,
  };
}

export function BeamsBackground({
  className,
  children,
  intensity = "strong",
}: BeamsBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const beamsRef = useRef<Beam[]>([]);
  const animationFrameRef = useRef<number>(0);
  const MINIMUM_BEAMS = 20;

  const opacityMap = {
    subtle: 0.68,
    medium: 0.84,
    strong: 1,
  } as const;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const updateCanvasSize = () => {
      const dpr = window.devicePixelRatio || 1;
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;

      canvas.width = Math.floor(viewportWidth * dpr);
      canvas.height = Math.floor(viewportHeight * dpr);
      canvas.style.width = `${viewportWidth}px`;
      canvas.style.height = `${viewportHeight}px`;

      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

      const totalBeams = Math.floor(MINIMUM_BEAMS * 1.5);
      beamsRef.current = Array.from({ length: totalBeams }, () =>
        createBeam(viewportWidth, viewportHeight)
      );
    };

    updateCanvasSize();
    window.addEventListener("resize", updateCanvasSize);

    function resetBeam(beam: Beam, index: number, totalBeams: number) {
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;
      const column = index % 3;
      const spacing = viewportWidth / 3;

      beam.y = viewportHeight + 120;
      beam.x = column * spacing + spacing / 2 + (Math.random() - 0.5) * spacing * 0.5;
      beam.width = 96 + Math.random() * 96;
      beam.speed = 0.45 + Math.random() * 0.38;
      beam.hue = 324 + (index * 22) / totalBeams;
      beam.opacity = 0.2 + Math.random() * 0.1;
      return beam;
    }

    function drawBeam(canvasCtx: CanvasRenderingContext2D, beam: Beam) {
      canvasCtx.save();
      canvasCtx.translate(beam.x, beam.y);
      canvasCtx.rotate((beam.angle * Math.PI) / 180);

      const pulsingOpacity =
        beam.opacity * (0.8 + Math.sin(beam.pulse) * 0.2) * opacityMap[intensity];

      const gradient = canvasCtx.createLinearGradient(0, 0, 0, beam.length);
      gradient.addColorStop(0, `hsla(${beam.hue}, 92%, 67%, 0)`);
      gradient.addColorStop(0.1, `hsla(${beam.hue}, 92%, 67%, ${pulsingOpacity * 0.55})`);
      gradient.addColorStop(0.4, `hsla(${beam.hue}, 92%, 67%, ${pulsingOpacity})`);
      gradient.addColorStop(0.6, `hsla(${beam.hue}, 92%, 67%, ${pulsingOpacity})`);
      gradient.addColorStop(0.9, `hsla(${beam.hue}, 92%, 67%, ${pulsingOpacity * 0.55})`);
      gradient.addColorStop(1, `hsla(${beam.hue}, 92%, 67%, 0)`);

      canvasCtx.fillStyle = gradient;
      canvasCtx.fillRect(-beam.width / 2, 0, beam.width, beam.length);
      canvasCtx.restore();
    }

    function animate() {
      ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
      ctx.filter = "blur(34px)";

      const totalBeams = beamsRef.current.length;
      beamsRef.current.forEach((beam, index) => {
        beam.y -= beam.speed;
        beam.pulse += beam.pulseSpeed;

        if (beam.y + beam.length < -120) {
          resetBeam(beam, index, totalBeams);
        }

        drawBeam(ctx, beam);
      });

      animationFrameRef.current = requestAnimationFrame(animate);
    }

    animate();

    return () => {
      window.removeEventListener("resize", updateCanvasSize);
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [intensity]);

  return (
    <div
      className={cn(
        "relative min-h-screen w-full overflow-hidden",
        className
      )}
      style={{
        background:
          "radial-gradient(circle at 82% 14%, rgba(80, 80, 80, 0.06), transparent 36%), radial-gradient(circle at 12% 82%, rgba(60, 60, 60, 0.04), transparent 32%), linear-gradient(145deg, #060608 0%, #0b0c10 50%, #12141c 100%)",
      }}
    >
      <canvas
        ref={canvasRef}
        className="absolute inset-0"
        style={{ filter: "blur(16px)" }}
      />

      <motion.div
        className="absolute inset-0"
        animate={{
          opacity: [0.04, 0.16, 0.04],
        }}
        transition={{
          duration: 10,
          ease: "easeInOut",
          repeat: Number.POSITIVE_INFINITY,
        }}
        style={{
          background:
            "radial-gradient(circle at 50% 10%, rgba(70, 70, 70, 0.05), transparent 50%)",
          backdropFilter: "blur(50px)",
        }}
      />

      <div className="relative z-10 flex h-screen w-full items-center justify-center px-4">
        {children ?? (
          <div className="flex flex-col items-center justify-center gap-5 text-center">
            <motion.h1
              className="text-5xl font-semibold tracking-tight text-[#ffe7f6] md:text-7xl lg:text-8xl"
              initial={{ opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
            >
              EtherVap
              <br />
              Beams
            </motion.h1>
            <motion.p
              className="text-base tracking-tight text-[#ffd6ea]/85 md:text-2xl lg:text-3xl"
              initial={{ opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.82 }}
            >
              Liquid market visuals with the active hero palette
            </motion.p>
          </div>
        )}
      </div>
    </div>
  );
}
