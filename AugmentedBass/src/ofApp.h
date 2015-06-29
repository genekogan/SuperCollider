#pragma once

#include "ofMain.h"
#include "SuperCollider.h"



class ofApp : public ofBaseApp{
    
public:
    void setup();
    void update();
    void draw();
    
    void keyPressed(int key);
    void keyReleased(int key);
    void mouseMoved(int x, int y );
    void mouseDragged(int x, int y, int button);
    void mousePressed(int x, int y, int button);
    void mouseReleased(int x, int y, int button);
    void windowResized(int w, int h);
    void dragEvent(ofDragInfo dragInfo);
    void gotMessage(ofMessage msg);
    
    
    SuperCollider sc3;
    
    SuperColliderSynth *bufWriter, *bufReader;
    ofxSCBuffer *buffer;
    ofxSCBus *phaseBus, *minSigBus;
    ofxSCBus *audioBus1, *audioBus2;
    
    ofParameter<float> isManual;
    ofParameter<float> manualGate;
    ofParameter<float> gain;
    ofParameter<float> delayTime;
    ofParameter<float> decayTime;
};
