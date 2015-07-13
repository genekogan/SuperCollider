#pragma once

#include "ofMain.h"
#include "ofxSuperCollider.h"


// trigger = Trig1 -> OscFunc

class SuperColliderSynthParameter
{
public:
    SuperColliderSynthParameter(ofxSCSynth *synth, string name, float value, float min, float max);
    void parameterChanged(float & v);
    ofParameter<float> & getParameter() {return parameter;}
private:
    ofxSCSynth *synth;
    ofParameter<float> parameter;
};

class SuperColliderSynthGate
{
public:
    SuperColliderSynthGate(ofxSCSynth *synth, string name, bool trigger);
    void parameterChanged(bool & v);
    ofParameter<bool> & getParameter() {return parameter;}
    bool isTrigger() {return trigger;}
private:
    ofxSCSynth *synth;
    ofParameter<bool> parameter;
    bool trigger;
};


class SuperColliderSynth
{
public:
    SuperColliderSynth(string name, ofxSCGroup *group=NULL);
    ~SuperColliderSynth();
    
    string getName() {return synth->getName();}
    string getInfo();
    
    ofxSCGroup * getGroup() {return group;}
    ofxSCSynth * getSynth() {return synth;}
    map<string,SuperColliderSynthParameter*> & getParameters() {return parameters;}
    map<string,SuperColliderSynthGate*> & getGates() {return gates;}
    vector<string> & getBuffers() {return buffers;}
    vector<string> & getControlBusses() {return controlBusses;}
    vector<string> & getAudioBusses() {return audioBusses;}

    ofParameter<float> & addParameter(string name, float value, float min, float max);
    ofParameter<bool> & addGate(string name);
    ofParameter<bool> & addTrigger(string name);
    void addBuffer(string name);
    void addControlBus(string name);
    void addAudioBus(string name);
    
    void set(string arg, double value);

    void create();
    void addToHead();
    void addToTail();
    void grain() {synth->grain();}
    void free() {synth->free();}
    
protected:
    
    ofxSCSynth *synth;
    ofxSCGroup *group;
    
    map<string,SuperColliderSynthParameter*> parameters;
    map<string,SuperColliderSynthGate*> gates;
    vector<string> buffers;
    vector<string> controlBusses;
    vector<string> audioBusses;
};


class SuperCollider
{
public:
    ~SuperCollider();
    virtual void draw();

    ofxSCGroup * addGroup(string name);
    SuperColliderSynth * addSynth(string name, ofxSCGroup *group=NULL);
    ofxSCBuffer * addBuffer(string name, int frames, int channels);
    ofxSCBus * addControlBus(string name, int channels);
    ofxSCBus * addAudioBus(string name, int channels);
    
    void readFromFile(string synthType, string synthFile, ofxSCGroup *group=NULL);
    
protected:
    map<string,SuperColliderSynth*> synths;
    map<string,ofxSCBuffer*> buffers;
    map<string,ofxSCBus*> bussesK;
    map<string,ofxSCBus*> bussesA;
    vector<ofxSCGroup*> groups;
};
