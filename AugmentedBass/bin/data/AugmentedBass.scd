(
s.quit;
s.options.memSize = 65000;
s.boot;
)


{SoundIn.ar(0)}.scope
{SinOsc.ar(SinOsc.kr(MouseX.kr(0.01, 10), 0, 400, 400), 0, MouseY.kr)}.play




(
SynthDef(\bufWriter, {
	arg rate=1, channel=0, bufnum, phasBuf, minSigBus, gateBus, manual=0, manualGate=0;
	var in, avg, gate, phase;
	in = SoundIn.ar(channel);
	avg = Amplitude.kr(in, 20, 30);
	gate = (manual * manualGate) + ((1 - manual)*(avg > (0.001*In.kr(minSigBus))));
//	[gate, avg, manual, manualGate, 0.001*In.kr(minSigBus)].poll(10).postln;
//	[gate, avg].poll(100).postln;
//	gate.poll(10).postln;
	phase = Phasor.ar(gate, BufRateScale.kr(bufnum) * gate * rate, 0, BufFrames.kr(bufnum));
//	phase.poll(100).postln;
	BufWr.ar(in, bufnum, phase);
	Out.kr(phasBuf, phase);
	Out.kr(gateBus, gate);
	0.0;
}).add;

SynthDef(\bufReader, {
	arg rate=1, bufnum, phasBuf, outBus=0, gateBus, overlap;
	var out, phase, isplay;
	isplay = (1-overlap) * (1-In.kr(gateBus)) + overlap;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate, 0, In.kr(phasBuf));
	out = BufRd.ar(1, bufnum, phase); //gain?
//	out = SinOsc.ar(SinOsc.kr(MouseX.kr(0.01, 10), 0, 400, 400), 0, 0.1);
	out.poll(10).postln;
	Out.ar(0, out);
}).add;


SynthDef(\bufComb, {
	arg rate=1, bufnum, phasBuf, outBus=0, gateBus, overlap, delayTime, decayTime, gain;
	var out, phase, isplay;
	isplay = (1-overlap) * (1-In.kr(gateBus)) + overlap;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate * isplay, 0, In.kr(phasBuf));
	out = CombC.ar(BufRd.ar(1, bufnum, phase), 2.0, delayTime, decayTime, gain);
	Out.ar(0, out!2);
}).add;

SynthDef(\bufAllPass, {
	arg bufnum, phasBuf, outBus=0, gateBus, overlap, delay=0.1, depth=0.08, rate=0.06, fdbk=0.0, decay=0.0;
	var out, phase, isplay, input, maxdelay, maxrate, dsig, mixed, local;

	isplay = (1-overlap) * (1-In.kr(gateBus)) + overlap;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate * isplay, 0, In.kr(phasBuf));

	maxdelay = 0.013;
    maxrate = 10.0;

	input = BufRd.ar(1, bufnum, phase);
	local = LocalIn.ar(1);

	dsig = AllpassL.ar(
		input + (local * fdbk),
		maxdelay * 2,
		LFPar.kr(
			rate * maxrate,
			0,
			depth * maxdelay,
			delay * maxdelay),
		decay);
	mixed = (input + dsig);
	LocalOut.ar(mixed);
	Out.ar(outBus, mixed);
}).add;


SynthDef(\bufGrains, {
	arg rate=1, bufnum, phasBuf, outBus=0, gateBus, overlap, trate=20, width=12, dispersion=0.01, position=0.5, gain=1.0;
	var out, phase, isplay, dur, clk, pos, pan;
	isplay = (1-overlap) * (1-In.kr(gateBus)) + overlap;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate * isplay, 0, In.kr(phasBuf));
    dur = width / trate;
    clk = Impulse.kr(trate);
//    pos = MouseX.kr(0, BufDur.kr(bufnum)) + TRand.kr(0, dispersion, clk);
	pos = BufDur.kr(bufnum) * (position + TRand.kr(0, dispersion, clk));
    pan = WhiteNoise.kr(0.6);
    out = gain * TGrains.ar(2, clk, bufnum, 1, pos, dur, pan, 0.1);
	Out.ar(outBus, out);
}).add;


)


