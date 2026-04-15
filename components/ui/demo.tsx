import { Component } from './etheral-shadow';
import { BeamsBackground } from './beams-background';

export const DemoOne = () => {
  return (
    <div className='flex h-screen w-full items-center justify-center bg-slate-950 p-4'>
      <div className='h-[620px] w-full max-w-6xl'>
        <Component
          color='rgba(236, 72, 153, 0.88)'
          animation={{ scale: 88, speed: 86 }}
          noise={{ opacity: 1, scale: 1.15 }}
          sizing='fill'
          title='EtherVap'
          subtitle='Tokenized capacity markets for always-on AI infrastructure.'
        />
      </div>
    </div>
  );
};

export const BeamsBackgroundDemo = () => {
  return <BeamsBackground />;
};
