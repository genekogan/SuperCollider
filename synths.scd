
/*
all pass
*/


(
s.quit;
s.options.memSize = 64000;
s.boot;
)

(
//==========================================
//  INPUTS
//==========================================


/*
@synthDef event
@name fmEvent
@param freq 100 1000
@audioBus busOut
*/
SynthDef(\fmEvent, { arg busOut=0, freq;
	var out;
	out = EnvGen.kr(Env.perc, doneAction: 2) * SinOsc.ar(freq, 0);
	Out.ar(busOut, out);
}).store;

////////////////////////////////////////////////



/*
@synthDef source
@name klanks
@param time 0 20 5
@audioBus busOut
*/
SynthDef(\klanks, {
	arg busOut=0, time=5;
	var sound, freqs, envs, rings, env, out, ampMult, numvoices;
	numvoices = 40;
	ampMult = 1.0 / numvoices;
	freqs = Array.fill(numvoices, Scale.major(\just).degrees+26+(0,12..110).choose.midicps);
	rings = {1.0.rand}.dup(numvoices);
	envs = { EnvGen.kr(Env.linen( time/3.0.rand, time/3.0.rand, time/3.0.rand, 1.0.rand ) )}.dup(numvoices);
	sound = WhiteNoise.ar(numvoices.reciprocal!2);
	sound = DynKlank.ar(`[freqs,envs,rings], sound );
	sound = sound * EnvGen.kr(Env.linen(time.rand,time/3,time.rand),doneAction:2);
	out = HPF.ar(sound, 120);
	6.do{sound = DelayC.ar(sound, 0.4, [0.4.rand,0.4.rand], 1/8, sound) };
	out = out * ampMult;
	Out.ar(busOut, out);
}).store;




/////////////

/*
@synthDef source
@name sourceBuffer
@buffer bufIn
@param reset 0 1
@param rate 0.5 1.5
@audioBus busOut
*/
SynthDef(\sourceBuffer, {
	arg busOut=0, bufIn, reset, rate;
	var trig, nf, idx, out;
	nf = BufFrames.kr(bufIn);
	//trig = In.kr(bus_trig);
	//idx = Phasor.ar(trig, BufRateScale.kr(buf), 0, nf, reset * nf);
	idx = Phasor.ar(1, rate * BufRateScale.kr(bufIn), 0, nf, reset * nf);
	out = BufRd.ar(1, bufIn, idx);
	//Out.kr(bus_cursor, idx);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name bufLoopRec
@param rate 0.5 1.5 1.0
@buffer bufnum
@gate isRecording
*/
SynthDef(\bufLoopRec, {
	arg channel=0, bufnum, isRecording=1, rate=1;
	var in;
	in = SoundIn.ar(channel);
	BufWr.ar(in, bufnum, Phasor.ar(0, BufRateScale.kr(bufnum) * rate * isRecording, 0, BufFrames.kr(bufnum)), 0);
}).store;



/*
@synthDef source
@name bufWriter
@param rate 0.5 2.0 1.0
@param manual 0 1 1
@param manualGate 0 1 0
@buffer bufnum
@controlBus phasBuf
@controlBus minSigBus
*/
SynthDef(\bufWriter, {
	arg rate=1, channel=0, bufnum, phasBuf, minSigBus, manual=0, manualGate=0;
	var in, avg, gate, phase;
	in = SoundIn.ar(channel);
	avg = Amplitude.kr(in, 20, 20);
	gate = (manual * manualGate) + ((1 - manual)*(avg > In.kr(minSigBus)));
	gate.poll(10).postln;
	phase = Phasor.ar(gate, BufRateScale.kr(bufnum) * gate * rate, 0, BufFrames.kr(bufnum));
	BufWr.ar(in, bufnum, phase);
	Out.kr(phasBuf, phase);
	0.0
}).store;



/*
@synthDef source
@name bufReader
@buffer bufnum
@controlBus phasBuf
@param rate 0.5 2.0 1.0
@audioBus busOut
*/
SynthDef(\bufReader, {
	arg rate=1, bufnum, phasBuf, busOut=0;
	var out, phase;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate, 0, In.kr(phasBuf));
	out = BufRd.ar(1, bufnum, phase); //gain?
	Out.ar(busOut, out);
}).store;




/*
@synthDef source
@name playBuf
@buffer buf
@param rate 0.5 1.5
@param start 0 1
@param time 0 10
@audioBus busOut
*/
SynthDef(\playBuf, { arg busOut=0, buf, rate, start, time;
	var out, env, startPos;
	startPos = start * BufSampleRate.kr(buf) * BufDur.kr(buf);
	env = EnvGen.kr(Env([0, 1, 1, 0], [0.1, time, 0.1]), 1, doneAction: 2);
	out = env * PlayBuf.ar(1, buf, rate, 1, startPos);
	Out.ar(busOut, out);
}).store;



/*
@synthDef source
@name granularSynth
@buffer bufnum
@param cursor 0 1
@param rate 0 8
@param duration 0 4
@param off 0 4
@param pom 0 1
@param amp 0 1
@audioBus busOut
*/
SynthDef(\granularSynth, {
    arg busOut = 0, bufnum, cursor, rate, duration, off, pom, amp, maxTrt = 4, maxDur = 4;
    var trt, dur, clk, pos, pan, pit, out;
    trt = maxTrt * pow(rate, 2.0);
    dur = maxDur * pow(duration, 2.0) / trt;
    clk = Impulse.kr(trt);
    pos = BufDur.kr(bufnum) * cursor + TRand.kr(-1*off, off, clk);
    pan = WhiteNoise.kr(1); // -1 to 1?
	pit = pom * BrownNoise.kr(1) + 1;
	out = TGrains.ar(2, clk, bufnum, pit, pos, dur, pan, amp);
	Out.ar(busOut, out!2);
}).store;



/*
@synthDef source
@name audioIn
@audioBus busOut
*/
SynthDef(\audioIn, { arg busOut=0;
	var out = SoundIn.ar(0);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name pickler
@param pulserate 1 30
@param ambience 0.001 0.99
@param numharmonics 1 16
@audioBus busOut
*/
SynthDef(\pickler, { arg busOut=0, pulserate, numharmonics, ambience;
	var trig, pitches, freq, idxfreq, out, out2, delay;
	pitches = -12 + [ 28, 36, 40, 47, 60, 64, 67, 71, 72, 76, 79, 83, 84 ];
	trig = Impulse.kr(pulserate);                    // trigger rate (5 hz)
	idxfreq = TIRand.kr(0, 13, trig);
	freq = Select.kr(idxfreq, pitches).midicps;
	out = Blip.ar(                                   // Generate blip
		freq,
		TRand.kr(1, numharmonics, trig),             // Num harmonics ranges from 1 to 12
		max(0, TRand.kr(-0.5, 0.4, trig))            // amplitude ranges from 0 to 0.4
	);
	out = Pan2.ar(out, TRand.kr(-1.0, 1.0, trig));   // Pan randomly
	out = out*EnvGen.kr(Env.perc(0, 1), trig);       // apply envelope to it
	out = Mix.ar({out}.dup(6))*0.2;
	delay = CombL.ar(out, 1.0, 4/6, 6);              // create comb filter delay
	out = out + delay;                               // play out + its delay from combL
	16.do({ out = AllpassC.ar(out, 1.0, DC.kr(Rand()).range(0.001, ambience), 8)});
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name sahliquid
@param atk 1 9
@param ctrFreq 0 100
@param clockRate 0 300
@audioBus busOut
*/
SynthDef(\sahliquid, { arg busOut=0, atk, ctrFreq, clockRate;
	var env, clockTime, clock, centerFreq, freq, panPos, patch;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), 1, doneAction: 2);
	centerFreq = 100 + 8000 * pow(ctrFreq, 2);
	clockTime = 2.0*clockRate.reciprocal;
	clock = Impulse.kr(clockRate, 0.4);
	freq = Latch.kr(WhiteNoise.kr(centerFreq * 0.5, centerFreq), clock);
	panPos = Latch.kr(WhiteNoise.kr, clock);
	patch = CombN.ar(
		Pan2.ar(
			SinOsc.ar(freq, 0, Decay2.kr(clock, 0.1 * clockTime, 0.9 * clockTime)),
			panPos
		), 0.3, 0.3, 2);
	Out.ar(busOut, env * patch);
}).store;


/*
@synthDef source
@name pluck1
@param pluck 0 1
@audioBus busOut
*/
SynthDef(\pluck1, { arg busOut=0, pluck;
	var pitch, out;
	pitch = [ 52, 57, 62, 67, 71, 76 ];   // e a d g b e
	out = Mix.arFill(pitch.size, { arg i;
		var pos, trigger1, trigger2, pluck1, pluck2, period, string1, string2;
		// place trigger points from 0.25 to 0.75
		pos = 0.25 + (i * 0.1);
		period = pitch.at(i).midicps.reciprocal;

		trigger1 = HPZ1.kr(pluck > pos).abs;
		pluck1 = PinkNoise.ar(Decay.kr(trigger1, 0.05));
		string1 = CombL.ar(pluck1, period, period, 4);

		trigger2 = HPZ1.kr(pluck > (pos + 0.015)).abs;
		pluck2 = PinkNoise.ar(Decay.kr(trigger2, 0.05));
		string2 = CombL.ar(pluck2, period/2, period/2, 4);

		Pan2.ar(string1 + string2, i * 0.2 - 0.5);
	});
	out = LeakDC.ar(LPF.ar(out, 12000));
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name pluck2
@param pluck 0 1
@audioBus busOut
*/
SynthDef(\pluck2, { arg busOut=0, pluck;
	var pitch1, pitch2, out;
	pitch1 = [ 52, 57, 62, 67, 71, 76, 81, 86, 91, 96 ];
	pitch2 = pitch1 + 7;
	out = Mix.arFill(pitch1.size, { arg i;
		var trigger, pluck1, pluck2, period1, period2, string1, string2;
		// place trigger points from 0.25 to 0.75
		trigger = HPZ1.kr(pluck > (0.25 + (i * 0.1)));

		pluck1 = PinkNoise.ar(Decay.kr(trigger.max(0), 0.05));
		period1 = pitch1.at(i).midicps.reciprocal;
		string1 = CombL.ar(pluck1, period1, period1, 4);

		pluck2 = BrownNoise.ar(Decay.kr(trigger.neg.max(0), 0.05));
		period2 = pitch2.at(i).midicps.reciprocal;
		string2 = CombL.ar(pluck2, period2, period2, -4);

		Pan2.ar(string1 + string2, i * 0.2 - 0.5);
	});
	out = LeakDC.ar(LPF.ar(out, 12000));
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name quickChimes
@audioBus busOut
*/
SynthDef(\quickChimes, { arg busOut=0;
	var out, exc, amp;
	amp = LFPulse.kr(12,0,0.1,0.002);
	exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
	out = Klank.ar(`[FloatArray.fill(8, { arg i; 100*pow(2,i) }),
			nil,
			FloatArray[1, 1, 1, 1]], exc);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name rezonator
@param freq 10 3000
@param rq 0.01 0.1 0.05
@param delTime 0.001 1.5
@audioBus busOut
*/
SynthDef(\rezonator, { arg busOut=0, freq, rq, delTime;
	var res, comb, out;
	res = RHPF.ar(
		LFSaw.ar([4, 7], 0.0, 0.2),
		freq,
		rq);
	//comb = CombC.ar(res, 1.5, MouseY.kr(0.001, 1.5, 3), 3.5);
	comb = CombC.ar(res, 1.5, delTime, 3.5); // ? deltime = MouseY.kr(0.001, 1.5, 3
	out = AllpassC.ar(comb, 0.6, 0.3, 4);
	Out.ar(0, out);
}).store;



/*
@synthDef source
@name warmChimes
@audioBus busOut
*/
SynthDef(\warmChimes, { arg busOut=0;
	var out, scale, specs, freqs, amps, rings,
	numRes = 5, bells = 20, pan;
	scale = [60, 62, 64, 67, 69].midicps;
	out = Mix.fill(bells, {
		freqs = Array.fill(numRes, {rrand(1, 15)*(scale.choose)});
		amps = Array.fill(numRes, {rrand(0.3, 0.9)});
		rings = Array.fill(numRes, {rrand(1.0, 4.0)});
		specs = [freqs, amps, rings].round(0.01);
		pan = (LFNoise1.kr(rrand(3, 6))*2).softclip;
		Pan2.ar( Klank.ar(`specs, Dust.ar(1/6, 0.03)), pan)
	});
	Out.ar(busOut, out);
}).store;



/*
@synthDef source
@name pmOsc
@param left 5 13
@param right 5 13
@param indexLow 1 3
@param indexHigh 4 10
@audioBus busOut
*/
SynthDef(\pmOsc, { arg busOut=0, left, right, indexLow, indexHigh;
	var pitches, idxpitch, pitch, timbre, trigger, env, index, out;
	pitches = -12 + [ 28, 36, 40, 47, 60, 64, 67, 71, 76, 79, 84 ];
	trigger = Impulse.kr([left, right]); // trigger
	//pitch = TRand.kr(36, 72, trigger).round(1); // C2 to C6
	idxpitch = TIRand.kr(0, pitches.size, trigger).round(1);
	pitch = Select.kr(idxpitch, pitches).midicps;
	timbre = LFNoise0.kr(1/20, mul: 0.2, add: 2); // mod control
	env = Linen.kr(trigger, releaseTime: 1/[left, right]); // envelope
	index = env * indexHigh + indexLow; // env scaled and offset for index
	out = PMOsc.ar(pitch, pitch*timbre, index, mul: env);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name repeater
@param freq 1 5000
@param lfoDepth 0 1500
@audioBus busOut
*/
SynthDef(\repeater, { arg busOut=0, freq, lfoDepth;
	var out, input, modulator, lfoRate, filtered;
	lfoRate = 200.0;
	freq = LFSaw.kr(lfoRate, 0, lfoDepth, lfoDepth * 1.2);
	filtered = RLPF.ar({WhiteNoise.ar(0.03)}.dup, freq, 0.1);
	input = CombN.ar(filtered, 4.0, 2.0, 0.5, 0.2, filtered);
	modulator = SinOsc.ar(freq, [0,0.5pi]);
	out = input * modulator;
	Out.ar(busOut, out);
}).store;



/*
@synthDef source
@name wormdig
@audioBus busOut
*/
SynthDef(\wormdig, { arg busOut=0;
	var out;
	var time = 60*7;
	var hex = {|f| 1 - LFTri.ar(f)};
	var line = {|s,e| Line.kr(s,e,time,1,0)};
	var hexes = hex.(line.(17,1647)) * hex.(line.(217,17)) * hex.(67) * hex.([55,55.1]) * 0.05;
	var verb1 = hexes * SinOsc.ar(300) * SinOsc.ar(0.01);
	var verb2 = hexes * SinOsc.ar(SinOsc.ar(0.0334).range(100, 157.7)) * SinOsc.ar(0.008);
	var verb3 = hexes * SinOsc.ar(SinOsc.ar(0.0234).range(200, 257.7)) * SinOsc.ar(0.0043);
	var verb4 = (hexes * 20 * SinOsc.ar(3257.7)).clip(-1,1) * SinOsc.ar(1257.7) * SinOsc.ar(0.023) / 30;
	var combine = verb1 + verb2 + verb3 + CombC.ar(verb4 * SinOsc.ar(Line.ar(300, 10000, 60*7)), 10, 1, 10, 1, verb4);
	combine = combine * EnvGen.ar(Env.linen(0.01, time - 15, 13));
	combine = combine + DelayC.ar(GVerb.ar(combine, [1.7, 1.8], 10, drylevel: 0), 10, Line.kr(0.01, 1, time), 0.5) * 0.1;
	combine = combine + LPF.ar(CombC.ar(combine, 20, Line.kr(1, 0.01, time), 20), LFTri.ar([0.0312, 0.0222]).range(50, 10000)) * 0.1;
	combine = Compander.ar(combine, combine, 0.5, 1, 1/20) * 8;
	combine = Compander.ar(combine, combine, 0.5, 1, 1/20) / 2.5;
	out = HPF.ar(combine, 55);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name rezlpf
@param freq 10 3000
@param rq 0.01 0.1
@audioBus busOut
*/
SynthDef(\rezlpf, { arg busOut=0, freq, rq;
	var out = RLPF.ar(                                    // resonant low pass filter
		LFSaw.ar([8, 12], 0, 0.2),               // in = sawtooth (amp 0.2, freq = [8hz, 12hz]
		//LFNoise1.ar([2, 3].choose, 1500, 1600),  // cutoff freq b/w 100 and 3100 hz, changed 2 or 3x a second
		freq,
		rq,                                    // reciproqal of Q
		mul: 0.4                                 // x 0.4
	);
	Out.ar(busOut, out);
}).store;



/*
@synthDef source
@name creepyBell
@param noiseFreq1 0 20
@param noiseFreq2 0 20
@trigger envGate
@audioBus busOut
*/
SynthDef(\creepyBell, {
	arg busOut = 0, gate = 1, atk = 5.0, noiseFreq1, noiseFreq2, envGate=0;
	var env, burst, burstEnv, bell, delay, dry, burstFreq = 500, freqs, amps, rings;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	burstEnv = EnvGen.kr(Env.perc(0, 0.05), envGate, 0.4);
	burst = SinOsc.ar(freq: burstFreq, mul: burstEnv);
	amps = Array.fill(10, {rrand(0.01, 0.1)});
	rings = Array.fill(10, {rrand(1.0, 6.0)});
	if ([true,false].choose, freqs = [100, 200, 800, 400, 1600, 3200, 6400], freqs = Array.fill(10, {exprand(100, 1100)}) );
	bell = Pan2.ar(
		Klank.ar(`[freqs, amps, rings], burst),
		rrand(-1.0, 1.0));
	delay = AllpassN.ar(bell, 2.5,
		[LFNoise1.kr(noiseFreq1, 1.5, 1.6), LFNoise1.kr(noiseFreq2, 1.5, 1.6)], 1, mul: 0.8);
	Out.ar(busOut, env * (bell + delay));
}).store;


/*
@synthDef source
@name organ
@param freq_high 0 1
@param freq_mid 0 1
@param freq_low 0 1
@audioBus busOut
*/
SynthDef(\organ, {
	arg busOut = 0, gate = 1, atk = 5.0, freq_high, freq_mid, freq_low;
	var env, klank1, klank2, klank3, n, harm, amp, ring, pitches, freq1, freq2, freq3, cnoiseMul;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	//pitches = [0, 3, 5, 7, 10, 12, 17, 22];
	pitches = [0, 3, 5, 7, 10, 12, 17, 22, 24, 29, 34];
	n = pitches.size;
	cnoiseMul = 0.006;	//-44, -20, 4
	freq1 = Select.kr(freq_high*n, 55+pitches).midicps;
	freq2 = Select.kr(freq_mid*n, 31+pitches).midicps;
	freq3 = Select.kr(freq_low*n,  7+pitches).midicps;
	harm = Control.names(\harm).kr(Array.series(4,1,1));
	amp = Control.names(\amp).kr(Array.fill(4,0.05));
	ring = Control.names(\ring).kr(Array.fill(4,1));
	klank1 = DynKlank.ar(`[harm,amp,ring], {ClipNoise.ar(cnoiseMul)}.dup, freq1);
	klank2 = DynKlank.ar(`[harm,amp,ring], {ClipNoise.ar(cnoiseMul)}.dup, freq2);
	klank3 = DynKlank.ar(`[harm,amp,ring], {ClipNoise.ar(cnoiseMul)}.dup, freq3);
	Out.ar(busOut, env * (klank1 + klank2 + klank3));
}).store;


/*
@synthDef source
@name ringMod
@param p1 0 1
@param p2 0 65
@param ratio_ 0 14
@audioBus busOut
*/
SynthDef(\ringMod, {
	arg busOut = 0, gate = 1, atk = 5.0, p1=0.5, p2=32.5, ratio_=7;
	var env, freq, ratio, modulator, carrier, sig;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	freq = LFNoise0.kr(p2+5, 80, 60).round(24).midicps;
	ratio = -2.0+ratio_;
	modulator = SinOsc.ar(freq * ratio, 0, 4.0);
	carrier = SinOsc.ar(freq, modulator, 0.5);
	sig = carrier!2;
	//8.do({ out = AllpassC.ar(out, 0.5, { Rand(0.001, 0.03) }.dup, 8)});
	2.do({ sig = AllpassC.ar(sig, 0.5, DC.kr(Rand()).range(0.001, 0.5*(3.asWarp.map(p1+0.001))), 8)});
	Out.ar(busOut, 0.2 * env * sig);
}).store;



/*
@synthDef source
@name strum
@param decay 0 1
@param decayTime_ 0 10
@param strum_ 0 1
@audioBus busOut
*/
SynthDef(\strum, {
	arg busOut = 0, gate = 1, atk = 5.0, z = 1, decay, decayTime_, strum_;
	var env, pitch1, pitch2, strum, sig, decayTime, cDecayTime;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	pitch1 = [ 52, 57, 62, 67, 71, 76, 81, 86 ];
	pitch2 = pitch1 + 12;

	strum = strum_;

	decayTime = 5.asWarp.map(decay);
	cDecayTime = decayTime_;

	sig = Mix.arFill(pitch1.size, { arg i;
		var trigger, pluck1, pluck2, period1, period2, string1, string2, pitchHop;
		// place trigger points from 0.25 to 0.75
		pitchHop = 0.5 / pitch1.size;
		trigger = HPZ1.kr(strum > (0.25 + (i * pitchHop)));

		pluck1 = PinkNoise.ar(Decay.kr(trigger.max(0), decayTime));
		period1 = pitch1.at(i).midicps.reciprocal;
		string1 = CombL.ar(pluck1, period1, period1, cDecayTime);

		pluck2 = BrownNoise.ar(Decay.kr(trigger.neg.max(0), decayTime));
		period2 = pitch2.at(i).midicps.reciprocal;
		string2 = CombL.ar(pluck2, period2, period2, -1*cDecayTime);

		Pan2.ar(string1 + string2, i * 0.2 - 0.5);
	});
	sig = LeakDC.ar(LPF.ar(sig, 12000));
	Out.ar(busOut, env * sig);
}).store;



/*
@synthDef source
@name ethereal
@param dur 0 20 8
@param freq 40 1000 440
@param spread 0.01 2 0.8
@param attack 0.01 0.8 0.3
@audioBus busOut
*/
SynthDef(\ethereal, {
	arg busOut=0, freq, dur, spread, attack;
	var num, harm, harma, detune, source, bandwidth, generator, snd, out;
	num = 8;
	harm = Array.geom(num, 1, 1.5);
	harma = Array.geom(num, 0.5, 0.8);
	detune = Array.fill(num, { LFNoise2.kr(1,0.01,1) });
	source = PinkNoise.ar;
	bandwidth = Rand(0.001,0.01);
	generator = [
		SinOsc.ar(freq*harm*detune, mul:harma*0.3).scramble,
		Resonz.ar(source, freq*harm*detune, bandwidth, mul:harma).scramble * 50
	].wchoose([0.2,0.8]);
	snd = Splay.ar(generator,spread);
	out = snd * LFGauss.ar(dur, attack, loop:0, doneAction:2);
	Out.ar(busOut, out);
}).store;



/*
@synthDef source
@name allPassRando
@param freq 1 100 16
@param pulse 0 30 8
@audioBus busOut
*/
SynthDef(\allPassRando, {
	arg busOut=0, pulse, freq;
	var texture, out;
	texture = TExpRand.ar(2e-4, 0.4, Impulse.ar(pulse)).round([2e-3,4e-3]);
	out = AllpassC.ar(SinOsc.ar(freq), 0.55, texture, 2);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name dutyTest
@param atk 0.01 10.0 1.0
@param fexp 0 5 1.0
@audioBus busOut
*/
SynthDef(\dutyTest, {
	arg busOut=0, atk, fexp;
	var in, dutyLevel, sawMult, freq, out;
	dutyLevel = Drand([0, Drand((0.4,0.5..1))], inf);
	sawMult = Decay2.kr(x=Duty.kr(1/8, 0, dutyLevel), atk, 0.3);
	freq = Saw.ar(8, sawMult)**fexp;
	in = BRF.ar(freq, x*20+[45.1,45], 0.1);
	out = LeakDC.ar(in).tanh;
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name cheesyMoog
@param pulse 1 24 8
@param swipe 8 200 24
@param freq 10 200 90
@audioBus busOut
*/
SynthDef(\cheesyMoog, {
	arg busOut=0, pulse=8, freq=90, swipe=24;
	var a, freqMoog, moog, out;
	a = LFNoise0.ar(pulse);
	freqMoog = a * XLine.ar(1, 39, 99, 99, 0, 2);
	moog = MoogFF.ar(Saw.ar(LFNoise0.ar(4,333,666)), freqMoog);
	out = SinOsc.ar(Pulse.ar(1)*swipe) + SinOsc.ar(freq+(a*freq)) + moog;
	Out.ar(busOut, out!2/3);
}).store;


/*
@synthDef source
@name timewarp
@param rate 0.5 1.5 1.0
@param amp 0.0 1.0 0.5
@param freqScale 0.0 2.0 1.0
@param grainSize 0.0 1.0 0.2
@param overlaps 0 10 4
@param rnd 0.0 1.0 0.1
@buffer bufnum
@audioBus busOut
*/
SynthDef(\timewarp, {
	arg busOut=0, bufnum, rate=1, amp=0.0, freqScale=1, grainSize=0.2, overlaps=4, rnd=0.1;
	var in, filt;
	in = Pan2.ar(
		Warp1.ar(
			bufnum.numChannels,
			bufnum,
			LFSaw.kr(BufDur.kr(bufnum).reciprocal * rate,1,0.5,0.5),
			freqScale,
			grainSize,
			-1, overlaps, rnd));
	Out.ar(busOut, amp*in);
}).store;



/*
@synthDef source
@name comber
@param lf 1 40 4
@param midr 1 120 24,
@param del 0 1 0.2
@param decay 0 8 4
@audioBus busOut
*/
SynthDef(\comber, {
	arg busOut, lf = 4, midr = 24, del = 0.2, decay = 4;
	var comber = CombN.ar(
		SinOsc.ar(
			LFNoise1.kr(
				lf, // LFO
				midr, // range in MIDI
				LFSaw.kr(
					[8,7.23], //second LFO
					0,
					3,  // range in MIDI
					80  // offset in MIDI
				)
			).midicps,
			0,
			0.4
		),
		1.0,  // max delay
		del,  // actual delay
		decay     // decay
	);
	Out.ar(busOut, comber);
}).store;



/*
@synthDef source
@name harmonicBells
@audioBus busOut
*/
SynthDef(\harmonicBells, {
	arg busOut;
	var exc, amp, out;
	amp = LFPulse.kr(12,0,0.1,0.002);
	exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
	out = Klank.ar(`[FloatArray.fill(8, { arg i; 100*pow(2,i) }),
			nil,
			FloatArray[1, 1, 1, 1]], exc);
	Out.ar(busOut, out);
}).store;


/*
@synthDef source
@name phoneGlitch
@param inFreq 0 400 200
@param resetFreq 0 200 100
@param latchFreq 100 3000 2000
@param bwr 0.01 1.0 0.1
@audioBus busOut
*/
SynthDef(\phoneGlitch, {
	arg busOut=0, inFreq=200, resetFreq=100, latchFreq=2000, bwr=0.1;
	var out;
	out = Resonz.ar(
		LFNoise0.ar(inFreq),
		Latch.ar(BrownNoise.ar, Dust.kr(resetFreq)) * latchFreq + 500,
		bwr);
	Out.ar(busOut, out);
}).store;



/*
@synthDef source
@name vibraVocals
@param modfreq 1 4400 2000
@param modindex 0.01 10.0 0.1
@param addfreq 0 1000 440
@buffer bufnum
@audioBus busOut
*/
SynthDef(\vibraVocals, {
	arg busOut=0, bufnum, modfreq=2000, addfreq=440, modindex=5; // modfreq exponential, modindex linear
	var out, modulator;
	modulator = SinOsc.kr(modfreq, 0, modfreq*modindex, addfreq);
	out = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)* (modulator/addfreq), 1, 0, 1);
	Out.ar(busOut, out);
}).store;






//==========================================
//  MODS
//==========================================


/*
@synthDef modifier
@name pass
@audioBus busIn
@audioBus busOut
*/
SynthDef(\pass, { arg busOut=0, busIn;
	Out.ar(busOut, In.ar(busIn, 1));
}).store;


/*
@synthDef modifier
@name deladd
@param deltime 0 5
@audioBus busIn
@audioBus busOut
*/
SynthDef(\deladd, { arg busOut=0, busIn, deltime;
	var sig, out;
	sig = In.ar(busIn, 1);
	out = Mix.ar([sig, DelayC.ar(sig, 5.0, deltime)]);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name fxcomb
@param deltime 0 3
@param dectime 0 3
@audioBus busIn
@audioBus busOut
*/
SynthDef(\fxcomb, { arg busOut=0, busIn, deltime, dectime;
	var sig, out;
	sig = In.ar(busIn, 1);
	out = CombC.ar(sig, 3.0, deltime, dectime);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name freeverb
@param mix 0 1
@param room 0 1
@param damp 0 1
@audioBus busIn
@audioBus busOut
*/
SynthDef(\freeverb, {
	arg busOut=0, busIn, mix, room, damp;
	var in, out;
	in = In.ar(busIn, 2);
	out = FreeVerb.ar(in, mix, room, damp);
	Out.ar(busOut, out);
}).store;



/*
@synthDef modifier
@name gverb
@param spread 0 30 15
@param drylevel -20 0 -6
@param earlylevel -20 0 -11
@param taillevel -20 0 -13
@param revtime 0 1 0.5
@param damping 0 1 0.5
@param inputbw 0 1 0.5
@audioBus busIn
@audioBus busOut
*/
SynthDef(\gverb, {
	arg busOut=0, busIn, spread=15, drylevel, earlylevel, taillevel, revtime=0.5, damping=0.5, inputbw=0.5;
    var input, roomsize;
	input = In.ar(busIn, 1);
	roomsize = 5; //In.kr(~midi1)*2;
	Out.ar(busOut, GVerb.ar(input,
		roomsize, revtime, damping, inputbw, spread,
		drylevel.dbamp, earlylevel.dbamp, taillevel.dbamp,
		roomsize, 0.3) + input);
}).store;



/*
@synthDef modifier
@name pitchShift
@param pitchRatio 0 4
@param pitchDeviation 0 1
@param timeDispersion 0 1
@audioBus busIn
@audioBus busOut
*/
SynthDef(\pitchShift, { arg busIn, busOut=0, pitchRatio, pitchDeviaton, timeDispersion;
	var in, out;
	in = In.ar(busIn);
	out = PitchShift.ar(in, 0.05, pitchRatio, pitchDeviaton, timeDispersion);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name rlpf
@param freq 0 1000
@param rq 0 1
@audioBus busIn
@audioBus busOut
*/
SynthDef(\rlpf, { arg busIn, busOut=0, freq, rq;
	var in, out;
	in = In.ar(busIn);
	out = RLPF.ar(in, freq, rq);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name rhpf
@param freq 0 1000
@param rq 0 1
@audioBus busIn
@audioBus busOut
*/
SynthDef(\rhpf, { arg busIn, busOut=0, freq, rq;
	var in, out;
	in = In.ar(busIn);
	out = RHPF.ar(in, freq, rq);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name resonz
@param freq 0 1000
@param bwr 0 1
@audioBus busIn
@audioBus busOut
*/
SynthDef(\resonz, { arg busIn, busOut=0, freq, bwr;
	var in, out;
	in = In.ar(busIn);
	out = Resonz.ar(in, freq, bwr);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name ringz
@param freq 0 1000
@param dectime 0 3
@audioBus busIn
@audioBus busOut
*/
SynthDef(\ringz, { arg busIn, busOut=0, freq, dectime;
	var in, out;
	in = In.ar(busIn);
	out = Ringz.ar(in, freq, dectime);
	Out.ar(busOut, out);
}).store;


/*
@synthDef modifier
@name freqShift
@param freq 0 1000
@param phase 0 6
@audioBus busIn
@audioBus busOut
*/
SynthDef(\freqShift, { arg busIn, busOut=0, freq, phase;
	var in, out;
	in = In.ar(busIn);
	out = FreqShift.ar(in, freq, phase);
	Out.ar(busOut, out);
}).store;




/*
@synthDef modifier
@name flanger
@param delay 0 1 0.1
@param depth 0 0.2 0.08
@param rate 0 0.2 0.06
@param fdbk 0 1 0
@param decay 0 1 0
@audioBus busIn
@audioBus busOut
*/
SynthDef(\flanger, { arg busIn, busOut=0, delay=0.1, depth=0.08, rate=0.06, fdbk=0.0, decay=0.0;
    var input, maxdelay, maxrate, dsig, mixed, local;
    maxdelay = 0.013;
    maxrate = 10.0;
    input = In.ar(busIn);
    local = LocalIn.ar(1);
    dsig = AllpassL.ar( // the delay (you could use AllpassC (put 0 in decay))
        input + (local * fdbk),
        maxdelay * 2,
        LFPar.kr( // very similar to SinOsc (try to replace it) - Even use LFTri
            rate * maxrate,
            0,
            depth * maxdelay,
            delay * maxdelay),
        decay);
    mixed = input + dsig;
    LocalOut.ar(mixed);
    Out.ar(busOut, mixed);
}).store;



/*
@synthDef modifier
@name freeze
@gate freezePos
@audioBus busIn
@audioBus busOut
*/
SynthDef(\freeze, {
	arg busOut = 0, busIn, freezePos;
    var in, sampRate, chain;
	in = In.ar(busIn);
	sampRate = 2048;
    chain = FFT(LocalBuf(sampRate), in);
	chain = PV_MagFreeze(chain, freezePos);
    Out.ar(busOut, 0.5 * IFFT(chain).dup);
}).store;



/*
@synthDef modifier
@name stretchplayer
@param duration 1 30 12
@param start 0 1 0.5
@param end 0 1 0.55
@param time_curve 0 1 0
@param trans_start 0 1 0
@param trans_end 0 1 0
@param trans_curve 0 1 0
@param amp_start 0 1 0
@param amp_end 0 1 0
@param amp_curve 0 1 0
@param pan_start 0 1 0
@param pan_end 0 1 0
@param pan_curve 0 1 0
@param windowsize 0.01 0.1 0.05
@param overlaps 1 8 2
@buffer bufnum
@audioBus busOut
*/
SynthDef(\stretchplayer, {
	arg busOut=0, bufnum=0, duration=1,
	start=0, end=1, time_curve=0,
	trans_start=0, trans_end=0, trans_curve=0,
	amp_start=0, amp_end=0, amp_curve=0,
	pan_start=0, pan_end=0, pan_curve=0,
	windowsize=0.05,
	overlaps=2;
	var fade = duration/200;
	var fd_env = EnvGen.kr(Env.new([0,1,1,0],[fade,duration-(2*fade),fade], \sine), doneAction: 2);
	var tr_env = 2**(EnvGen.kr(Env.new([trans_start, trans_end], [duration], [trans_curve]))/12);
	var sp_env = EnvGen.ar(Env.new([start.min(1-(windowsize*(2**(trans_start/12))+0.03)),
		end.min(1-(windowsize*(2**(trans_end/12))+0.03))],
		[duration], [time_curve]));
	var amp_env = EnvGen.kr(Env.new([amp_start,amp_end],[duration],[amp_curve]));
	var pan_env = EnvGen.kr(Env.new([pan_start, pan_end],[duration],[pan_curve]));
	var sig = WarpZ.ar(1, bufnum, sp_env, tr_env, windowsize, -1, overlaps, 0, 4, 0, 0, amp_env.dbamp);
	Out.ar(busOut, Pan2.ar(sig * fd_env, pan_env));
}).store;



)