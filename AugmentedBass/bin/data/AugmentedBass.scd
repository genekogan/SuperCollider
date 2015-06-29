
s.quit
s.options.memSize = 65000
s.boot



(
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
}).add;

SynthDef(\bufReader, {
	arg rate=1, bufnum, phasBuf, gain=1.0, hpf_freq=0, outBus=0;
	var out, phase;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate, 0, In.kr(phasBuf));
	out = BufRd.ar(1, bufnum, phase); //gain?
	Out.ar(outBus, out!2);
}).add;
)








(
SynthDef(\bufReader, {
	arg rate=1, bufnum, phasBuf, gain=1.0, hpf_freq=0, delayTime, decayTime;
	var out, phase;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate, 0, In.kr(phasBuf));
	out = HPF.ar(BufRd.ar(1, bufnum, phase), hpf_freq, gain);
//	out = CombC.ar(out, 2.0, delayTime, decayTime);
	out = DelayC.ar(out, 0.02, Saw.kr(0.1, 0.01, 0.01));
	Out.ar(0, out!2);
}).add;
)

(
SynthDef(\bufReader, {
	arg bufnum, phasBuf, gain=1.0, hpf_freq=0, delay=0.1, depth=0.08, rate=0.06, fdbk=0.0, decay=0.0, manualGate=0;
	var out, input, phase, maxdelay, maxrate, dsig, mixed, local;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum), 0, In.kr(phasBuf));
	out = HPF.ar(BufRd.ar(1, bufnum, phase), hpf_freq, gain);

    maxdelay = 0.013;
    maxrate = 10.0;

	input = out;
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
	mixed = (input + dsig) * (1-manualGate);
	LocalOut.ar(mixed);
	Out.ar(0, mixed);
}).add;
)







Synth(\bufWriter, [\bufnum, ~buf, \phasBuf, ~phasBuf, \channel, 0])
Synth(\bufReader, [\bufnum, ~buf, \phasBuf, ~phasBuf])
~minsig.set(0.1)




/////======/////======/////======/////======/////======/////======/////======/////======/////======
/////======/////======/////======/////======/////======/////======/////======/////======/////======


~buf = Buffer.alloc(s, s.sampleRate * 2.0, 1);

~phasBuf = Bus.control(s, 1);
~minsig = Bus.control(s, 1);

(
SynthDef(\bufwr, {
	arg rate=1, bufnum, phasBuf;
	var in, avg, gate, phase;
	in = SoundIn.ar(0);
	avg = Amplitude.kr(in, 10, 10);
	gate = (avg > 0.05);
	gate.poll(20).postln;
	phase = Phasor.ar(gate, BufRateScale.kr(bufnum) * gate * rate, 0, BufFrames.kr(bufnum));
	BufWr.ar(in, bufnum, phase);
	Out.kr(phasBuf, phase);
	0.0
}).add;
)




(
SynthDef(\bufrd, {
	arg rate=1, bufnum, phasBuf;
	var out, phase;
	phase = Phasor.ar(1, BufRateScale.kr(bufnum) * rate, 0, In.kr(phasBuf));
	out = BufRd.ar(1, bufnum, phase);
	Out.ar(0, out!2);
}).add;
)

BufRateScale.kr(~buf)

{Linen.kr(1, 1, In.kr(phasBuf), 0).poll(100).postln}.play

(
SynthDef(\bufrd2, {
	arg rate=1, bufnum, phasBuf, pulse=1;
	var out, pos, gate;
	gate = Impulse.kr(pulse);
	pos = K2A.ar(Linen.kr(gate, In.kr(phasBuf)/s.sampleRate, In.kr(phasBuf), 0));
	out = BufRd.ar(1, bufnum, pos);
	Out.ar(0, out!2);
}).add;
)


(
SynthDef(\bufrd3, {
	arg rate=1, bufnum, phasBuf;
	var env, out;
	env = EnvGen.kr(Env([0, 1, 1, 0], [0.05, In.kr(phasBuf)/s.sampleRate - 0.1, 0.05]), doneAction: 2);
	out = env * PlayBuf.ar(1, bufnum);
	Out.ar(0, out!2);
}).add;
)






~minsig.set(1.0)
~w = Synth(\bufwr, [\bufnum,~buf, \phasBuf, ~phasBuf])
~r = Synth(\bufrd, [\bufnum, ~buf, \phasBuf, ~phasBuf])

~r = Synth(\bufrd2, [\bufnum, ~buf, \phasBuf, ~phasBuf])
~r.set(\pulse, 0.2)


(Task(({
	8.do({
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	0.3.wait;
	Synth(\bufrd3, [\bufnum, ~buf, \phasBuf, ~phasBuf]);
	})
})).play
)

~w.free
~r.free


/////======/////======/////======/////======/////======/////======/////======/////======/////======
/////======/////======/////======/////======/////======/////======/////======/////======/////======


(
~buf = [ Buffer.alloc(s, s.sampleRate * 2.0, 1),
	Buffer.alloc(s, s.sampleRate * 2.0, 1),
	Buffer.alloc(s, s.sampleRate * 2.0, 1),
	Buffer.alloc(s, s.sampleRate * 2.0, 1)];

~phasBuf = [ Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1) ];
~minsig = Bus.control(s, 1);
)


(
SynthDef(\bufwr, {
	arg rate=1, bufnum, phasBuf;
	var in, avg, gate, phase;
	in = SoundIn.ar(0);
	avg = Amplitude.kr(in, 10, 10);
	gate = (avg > 0.05);
	gate.poll(20).postln;
	phase = Phasor.ar(gate, BufRateScale.kr(bufnum) * gate * rate, 0, BufFrames.kr(bufnum));
	BufWr.ar(in, bufnum, phase);
	Out.kr(phasBuf, phase);
	0.0
}).add;

SynthDef(\bufrd, {
	arg rate=1, bufnum, phasBuf;
	var env, out;
	env = EnvGen.kr(Env([0, 1, 1, 0], [0.05, In.kr(phasBuf)/s.sampleRate - 0.1, 0.05]), doneAction: 2);
	out = env * PlayBuf.ar(1, bufnum);
	Out.ar(0, out!2);
}).add;
)


(
OSCFunc({arg msg; ~w0 = Synth(\bufwr, [\bufnum, ~buf[0], \phasBuf, ~phasBuf[0]])}, '/rec0/', nil);
OSCFunc({arg msg; ~w1 = Synth(\bufwr, [\bufnum, ~buf[1], \phasBuf, ~phasBuf[1]])}, '/rec1/', nil);
OSCFunc({arg msg; ~w2 = Synth(\bufwr, [\bufnum, ~buf[2], \phasBuf, ~phasBuf[2]])}, '/rec2/', nil);
OSCFunc({arg msg; ~w3 = Synth(\bufwr, [\bufnum, ~buf[3], \phasBuf, ~phasBuf[3]])}, '/rec3/', nil);
OSCFunc({arg msg; ~w0.free }, '/stop0/', nil);
OSCFunc({arg msg; ~w1.free }, '/stop1/', nil);
OSCFunc({arg msg; ~w2.free }, '/stop2/', nil);
OSCFunc({arg msg; ~w3.free }, '/stop3/', nil);
OSCFunc({arg msg; ~r0 = Synth(\bufrd, [\bufnum, ~buf[0], \phasBuf, ~phasBuf[0]])}, '/play0/', nil);
OSCFunc({arg msg; ~r1 = Synth(\bufrd, [\bufnum, ~buf[1], \phasBuf, ~phasBuf[1]])}, '/play1/', nil);
OSCFunc({arg msg; ~r2 = Synth(\bufrd, [\bufnum, ~buf[2], \phasBuf, ~phasBuf[2]])}, '/play2/', nil);
OSCFunc({arg msg; ~r3 = Synth(\bufrd, [\bufnum, ~buf[3], \phasBuf, ~phasBuf[3]])}, '/play3/', nil);
OSCFunc({arg msg; ~r0.free }, '/pause0/', nil);
OSCFunc({arg msg; ~r1.free }, '/pause1/', nil);
OSCFunc({arg msg; ~r2.free }, '/pause2/', nil);
OSCFunc({arg msg; ~r3.free }, '/pause3/', nil);
)






/////======/////======/////======/////======/////======/////======/////======/////======/////======
/////======/////======/////======/////======/////======/////======/////======/////======/////======


s.boot
h={Sound In.ar(0)}.play
h.free
(
~buf = [ Buffer.alloc(s, s.sampleRate * 4.0, 1),
	Buffer.alloc(s, s.sampleRate * 4.0, 1),
	Buffer.alloc(s, s.sampleRate * 4.0, 1),
	Buffer.alloc(s, s.sampleRate * 4.0, 1)];

~phasBuf = [ Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1) ];
~minsig = Bus.control(s, 1);
)


(
SynthDef(\bufwr, {
	arg rate=1, bufnum, innum=0, phasBuf;
	var in, avg, gate, phase;
	in = SoundIn.ar(innum);
	avg = Amplitude.kr(in, 10, 10);
	gate = (avg > In.kr(~minsig));
	gate.poll(20).postln;
	phase = Phasor.ar(gate, BufRateScale.kr(bufnum) * gate * rate, 0, BufFrames.kr(bufnum));
	BufWr.ar(in, bufnum, phase);
	Out.kr(phasBuf, phase);
	0.0
}).add;

SynthDef(\bufrd, {
	arg rate=1, bufnum, phasBuf;
	var env, out;
	env = EnvGen.kr(Env([0, 1, 1, 0], [0.05, In.kr(phasBuf)/s.sampleRate - 0.1, 0.05]), doneAction: 2);
	out = env * PlayBuf.ar(1, bufnum);
	Out.ar(0, out!2);
}).add;
)


~minsig.set(0.01)

(
OSCFunc({arg msg; ~w0 = Synth(\bufwr, [\bufnum, ~buf[0], \phasBuf, ~phasBuf[0], \innum, msg[1]])}, '/rec0/', nil);
OSCFunc({arg msg; ~w1 = Synth(\bufwr, [\bufnum, ~buf[1], \phasBuf, ~phasBuf[1], \innum, msg[1]])}, '/rec1/', nil);
OSCFunc({arg msg; ~w2 = Synth(\bufwr, [\bufnum, ~buf[2], \phasBuf, ~phasBuf[2], \innum, msg[1]])}, '/rec2/', nil);
OSCFunc({arg msg; ~w3 = Synth(\bufwr, [\bufnum, ~buf[3], \phasBuf, ~phasBuf[3], \innum, msg[1]])}, '/rec3/', nil);
OSCFunc({arg msg; ~w0.free }, '/stop0/', nil);
OSCFunc({arg msg; ~w1.free }, '/stop1/', nil);
OSCFunc({arg msg; ~w2.free }, '/stop2/', nil);
OSCFunc({arg msg; ~w3.free }, '/stop3/', nil);
OSCFunc({arg msg; ~r0 = Synth(\bufrd, [\bufnum, ~buf[0], \phasBuf, ~phasBuf[0]])}, '/play0/', nil);
OSCFunc({arg msg; ~r1 = Synth(\bufrd, [\bufnum, ~buf[1], \phasBuf, ~phasBuf[1]])}, '/play1/', nil);
OSCFunc({arg msg; ~r2 = Synth(\bufrd, [\bufnum, ~buf[2], \phasBuf, ~phasBuf[2]])}, '/play2/', nil);
OSCFunc({arg msg; ~r3 = Synth(\bufrd, [\bufnum, ~buf[3], \phasBuf, ~phasBuf[3]])}, '/play3/', nil);
)

/*
// processing code
// goes with BufOSC.pde
*/