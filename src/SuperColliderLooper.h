#pragma once

#include "ofMain.h"
#include "ofxBpm.h"
#include "ofxUI.h"
#include "SuperCollider.h"

/*
 Server.local.prepareForRecord;
 Server.local.record;
 Server.local.stopRecording;
 
 SynthDef(\buf_recorder, {
	arg bufnum, channel=0;
	RecordBuf.ar(SoundIn.ar(channel), bufnum, loop:0, doneAction:2);
 }).add;
 
 SynthDef(\buf_player, {
	arg out=0, bufnum, rate=1;
	var snd = PlayBuf.ar(1, bufnum, rate, loop:0, doneAction:2);
	OffsetOut.ar(out, snd!2)
 }).add;
 
 
 */


class SuperColliderLoopElement
{
public:
    SuperColliderLoopElement(SuperCollider * sc3, int numBeats, int index);
    
    void update(float t);

    void setBeat(int beat);
    void setSolo(bool solo);
    void setMute(bool mute);

    void setPlaying(bool isPlay);
    void setToRecord(bool toRecord);
    void setRecording(bool isRecord);
    
    bool getPlaying() {return isPlay;}
    bool getRecording() {return isRecord;}
    bool getToRecord() {return toRecord;}
    bool getSolo() {return solo;}
    int getNumBeats() {return numBeats;}
    int getSkip() {return skip;}
    
    ofEvent<SuperColliderLoopElement*> soloEvent, deleteEvent;
    
private:
    void guiEvent(ofxUIEventArgs &e);

    void beginRecording();
    void play();
    
    SuperColliderSynth *bufWriter, *bufReader;
    ofxSCBuffer *buffer;
    
    ofxUICanvas *gui;
    ofxUIMinimalSlider *progressSlider;

    bool isPlay, isRecord, toRecord, solo, mute;
    int beat, numBeats, skip, count;
    float t0;
    float volume;
};


class SuperColliderLooper
{
public:
    void setup(SuperCollider *sc3);
    void update();

    void addNewElement(int numBeats, int index);
    void setBpm(int bpm);
    
private:
    void guiEvent(ofxUIEventArgs &evt);
    void eventSolo(SuperColliderLoopElement* &evt);
    void eventDelete(SuperColliderLoopElement* &evt);
    void beatEvent();
    
    SuperCollider *sc3;
    vector<SuperColliderLoopElement*> elements;
    
    ofxBpm clock;
    int bpm;
    bool click;
    
    ofxUICanvas *gui;
    ofxUIRadio *guiBeat;
    
    int beat;
    float timeLast, timeInterval;
    ofSoundPlayer soundClick;    
};

