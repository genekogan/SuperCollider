#pragma once

#include "ofMain.h"
#include "SuperCollider.h"
#include "ofxUI.h"


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
    
    void guiEvent(ofxUIEventArgs & evt) {
        if (evt.getName() == "manual" || evt.getName() == "gate" || evt.getName() == "overlap") {
            updateManual();
        }
        else if (evt.getName() == "minSigBus") {
            minSigBus->set(evt.getSlider()->getValue());
        }
        else if (evt.getName() == "Playback") {
            evt.getToggle()->getValue() ? bufReader->create() : bufReader->free();
        }
    }
    
    void guiCombEvent(ofxUIEventArgs & evt) {
        if (evt.getName() == "On") {
            evt.getToggle()->getValue() ? comb->create() : comb->free();
        }
        else {
            comb->set(evt.getName(), evt.getSlider()->getValue());
        }
    }

    void guiAllPassEvent(ofxUIEventArgs & evt) {
        if (evt.getName() == "On") {
            evt.getToggle()->getValue() ? allpass->create() : allpass->free();
        }
        else {
            allpass->set(evt.getName(), evt.getSlider()->getValue());
        }
    }

    void guiGrainsEvent(ofxUIEventArgs & evt) {
        if (evt.getName() == "On") {
            evt.getToggle()->getValue() ? grains->create() : grains->free();
        }
        else {
            grains->set(evt.getName(), evt.getSlider()->getValue());
        }
    }

    void updateManual() {
        bufWriter->set("manual", isManual? 1 : 0);
        bufWriter->set("manualGate", manualGate ? 1 : 0);

        bufReader->set("overlap", overlap ? 1 : 0);
        comb->set("overlap", overlap ? 1 : 0);
        allpass->set("overlap", overlap ? 1 : 0);
        grains->set("overlap", overlap ? 1 : 0);
    }
    
    void exit() {
        comb->free();
        allpass->free();
        grains->free();
        bufReader->free();
        bufWriter->free();
    }
    
    SuperCollider sc3;
    
    SuperColliderSynth *bufWriter, *bufReader;
    SuperColliderSynth *comb, *allpass, *grains;
    
    ofxSCBuffer *buffer;
    ofxSCBus *phaseBus, *minSigBus, *gateBus;
    
    bool isManual, manualGate, overlap, playback;
    
    ofxUICanvas *gui, *guiComb, *guiAllPass, *guiGrains;
};
