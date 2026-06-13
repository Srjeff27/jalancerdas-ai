import { cn } from '@/lib/utils';

interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizeStyles = {
  sm: 'w-4 h-4',
  md: 'w-6 h-6',
  lg: 'w-10 h-10',
};

export function Spinner({ size = 'md', className }: SpinnerProps) {
  return (
    <div className="flex items-center justify-center">
      <div
        className={cn(
          'rounded-full border-2 border-gray-200 border-t-[#0071e3] animate-spin',
          sizeStyles[size],
          className
        )}
      />
    </div>
  );
}

export function PageSpinner() {
  return (
    <div className="flex items-center justify-center min-h-[400px]">
      <div className="text-center">
        <Spinner size="lg" />
        <p className="mt-3 text-sm text-gray-500">Memuat data...</p>
      </div>
    </div>
  );
}

export function InlineSpinner({ text }: { text?: string }) {
  return (
    <div className="flex items-center gap-2 text-sm text-gray-500">
      <Spinner size="sm" />
      {text && <span>{text}</span>}
    </div>
  );
}
