#pragma once

#include "ofMain.h"
#include "ofxUI.h"
#include "SuperCollider.h"


class SuperColliderUI : public SuperCollider {
public:
    void setupGui();
    void guiEvent(ofxUIEventArgs & evt);
    
    map<ofxSCGroup*, ofxUITabBar*> guiTabBar;
};
