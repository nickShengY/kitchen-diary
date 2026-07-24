import React, { useEffect, useState } from 'react';
import { KitchenAssetRef, isKitchenAssetRef } from '../services/kitchenAssetPack';

const useResolvedAssetSrc = (src?: string | KitchenAssetRef): string | undefined => {
  const [resolvedSrc, setResolvedSrc] = useState(
    typeof src === 'string' ? src : src?.url,
  );
  const srcKey = isKitchenAssetRef(src) ? src.path : src;

  useEffect(() => {
    let active = true;

    if (!src) {
      setResolvedSrc(undefined);
      return () => {
        active = false;
      };
    }

    if (typeof src === 'string') {
      setResolvedSrc(src);
      return () => {
        active = false;
      };
    }

    if (src.url) {
      setResolvedSrc(src.url);
      return () => {
        active = false;
      };
    }

    setResolvedSrc(undefined);
    src.load()
      .then((url) => {
        if (active) setResolvedSrc(url);
      })
      .catch(() => {
        if (active) setResolvedSrc(undefined);
      });

    return () => {
      active = false;
    };
    // srcKey captures the meaningful identity of ref-style sources.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [src, srcKey]);

  return resolvedSrc;
};

/** Renders pack art when available, otherwise the provided fallback (emoji/icon). */
export const PackAsset: React.FC<{
  src?: string | KitchenAssetRef;
  fallback: React.ReactNode;
  className?: string;
  imageClassName?: string;
}> = ({ src, fallback, className = '', imageClassName = '' }) => {
  const resolvedSrc = useResolvedAssetSrc(src);

  if (!resolvedSrc) {
    return <span className={className}>{fallback}</span>;
  }

  return (
    <img
      src={resolvedSrc}
      alt=""
      aria-hidden="true"
      className={`object-contain ${imageClassName || className}`}
      loading="lazy"
      decoding="async"
    />
  );
};

/**
 * Plays a motion asset the way the viewer expects to see it:
 * - real animated files (animations/*.webp) render as-is;
 * - 3x2 storyboard sheets (gif/transitions, gif/actions) are cropped to one
 *   panel and stepped through like a flipbook, so the sheet itself is never
 *   visible to the user.
 */
export const MotionScene: React.FC<{
  src?: string | KitchenAssetRef;
  alt: string;
  className?: string;
}> = ({ src, alt, className = '' }) => {
  const resolvedSrc = useResolvedAssetSrc(src);
  const assetPath = isKitchenAssetRef(src) ? src.path : typeof src === 'string' ? src : '';
  const isStoryboard = assetPath.startsWith('gif/');

  if (!resolvedSrc) return null;

  if (!isStoryboard) {
    return (
      <img
        src={resolvedSrc}
        alt={alt}
        className={`object-contain ${className}`}
        loading="eager"
        decoding="async"
      />
    );
  }

  return (
    <div
      role="img"
      aria-label={alt}
      className={`storyboard-flipbook ${className}`}
      style={{ backgroundImage: `url(${resolvedSrc})` }}
    />
  );
};

/** Renders pack art once resolved; renders nothing while loading or on miss. */
export const LazyAssetImage: React.FC<{
  src?: string | KitchenAssetRef;
  alt: string;
  className: string;
  loading?: 'eager' | 'lazy';
}> = ({ src, alt, className, loading = 'lazy' }) => {
  const resolvedSrc = useResolvedAssetSrc(src);

  if (!resolvedSrc) return null;

  return (
    <img
      src={resolvedSrc}
      alt={alt}
      className={className}
      loading={loading}
      decoding="async"
    />
  );
};
