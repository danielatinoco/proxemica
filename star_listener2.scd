


(
SynthDef(\bpfsaw, {
	arg atk=2, sus=0, rel=1.5, c1=1, c2=(-1),
	freq=500, cf=1500, rq=0.2, amp=1, out=0;
	var sig, env;
	env = EnvGen.kr(Env.new([0,1,1,0],[atk,sus,rel],[c1,0,c2]), doneAction:2);
	sig = Saw.ar(freq);
	sig = BPF.ar(sig, cf, rq);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;
)

(
SynthDef("blips", {
	arg freq = 150, numharm = 2, rel = 20, amp = 0.8;
	var snd, env;
	env = EnvGen.ar(Env.perc(releaseTime: rel), doneAction: 2);
	snd = Blip.ar([freq, freq*1.01], numharm, 0.3);
	snd = snd*env*amp;
	Out.ar(0, snd);
	}).add;
)

(
OSCdef('starlistener', {
	arg msg;
	Synth(
		\bpfsaw,
		[   \rel, 0.5,
			\freq, (Scale.minor.degrees+60).midicps.choose,
			// \amp, 0.25,
			\cf, msg[1],
			\rq, 0.3,
			\amp, msg[2],
		]
	);


}, "/starhit");
)

(
OSCdef('starlistener2', {
	arg msg;
    Synth.new(
		\bpfsaw,
		[
			\freq, 50,
			\amp, 0.7,
		]
	)

}, "/starhit2");
)

(
OSCdef('starlistener3', {
	arg msg;
    Synth.new(
		\bpfsaw,
		[
			\freq, 20,
			\amp, 0.7,
			\detune, 1,
			\cfmin, 50*40,
			\cfmax, 50*50,
			\pan, 0, //0.25, 0.5, 1
		]
	)

}, "/starhit3");
)

(
OSCdef('starlistener4', {
	arg msg;
  Synth("blips",[\rel,3, \freq,200, \amp, 0.1])
}, "/starhit4");
)

// (
// OSCdef('starlistener2', {
// 	arg msg;
// 	~marimba = Pbind(
// 		\instrument, \bpfsaw,
// 		\dur, Prand([1, 0.5]),
// 		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8]),
// 		\detune, 0,
// 		\rqmin, 0.005,
// 		\rqmax, 0.008,
// 		\cfmin, Prand((Scale.major.degrees+64).midicps, inf) * Prand([0.5,1,2,4]),
// 		\cfmax, Pkey(\cfmin),
// 		\atk, 3,
// 		\sus, 1,
// 		\rel, 5,
// 		\amp, 0.6,
// 		\out, 0,
// 	).play
//
// }, "/starhit2");
// )



