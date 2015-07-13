#include "SuperColliderUI.h"


void SuperColliderUI::setupGui()
{
    int x = 0;
    for (auto g : groups) {
        ofxUITabBar *tab = new ofxUITabBar();
        guiTabBar[g] = tab;
        tab->setPosition(x, 0);
        x += 360;
    }

    map<string,SuperColliderSynth*>::iterator it = synths.begin();
    for (; it != synths.end(); ++it)
    {
        ofxUICanvas *gui = new ofxUICanvas();
        gui->setName(it->second->getName());
        gui->addLabel(it->second->getName());
        gui->addSpacer();
        gui->addButton("Create", false);
        gui->addButton("Destroy", false);
        
        map<string,SuperColliderSynthParameter*>::iterator itp = it->second->getParameters().begin();
        for (; itp != it->second->getParameters().end(); ++itp)
        {
            gui->addSlider(itp->second->getParameter().getName(),
                           itp->second->getParameter().getMin(),
                           itp->second->getParameter().getMax(),
                           itp->second->getParameter());
        }

        map<string,SuperColliderSynthGate*>::iterator itg = it->second->getGates().begin();
        for (; itg != it->second->getGates().end(); ++itg)
        {
            if (itg->second->isTrigger()) {
                gui->addButton(itg->second->getParameter().getName(),
                               itg->second->getParameter());
            }
            else {
                gui->addToggle(itg->second->getParameter().getName(),
                               itg->second->getParameter());
            }
        }

        vector<string> availableBuffers, availableControlBusses, availableAudioBusses;
        map<string,ofxSCBuffer*>::iterator itbf = buffers.begin();
        map<string,ofxSCBus*>::iterator itkb = bussesK.begin();
        map<string,ofxSCBus*>::iterator itab = bussesA.begin();
        for (; itbf != buffers.end(); ++itbf) {availableBuffers.push_back(itbf->first);}
        for (; itkb != bussesK.end(); ++itkb) {availableControlBusses.push_back(itkb->first);}
        for (; itab != bussesA.end(); ++itab) {availableAudioBusses.push_back(itab->first);}
        availableAudioBusses.push_back("channel_0");
        availableAudioBusses.push_back("channel_1");

        for (auto b : it->second->getBuffers()) {gui->addDropDownList(b, availableBuffers);}
        for (auto b : it->second->getControlBusses()) {gui->addDropDownList(b, availableControlBusses);}
        for (auto b : it->second->getAudioBusses()) {gui->addDropDownList(b, availableAudioBusses);}
        
        gui->autoSizeToFitWidgets();
        ofAddListener(gui->newGUIEvent,this, &SuperColliderUI::guiEvent);
        guiTabBar[it->second->getGroup()]->addCanvas(gui);
    }
}

void SuperColliderUI::guiEvent(ofxUIEventArgs & evt)
{
    if (evt.getName() == "Create") {
        if (evt.getButton()->getValue() == 1) return;
        synths[evt.getParentName()]->create();
    }
    else if (evt.getName() == "Destroy") {
        if (evt.getButton()->getValue() == 1) return;
        synths[evt.getParentName()]->free();
    }
    else {
        //cout << evt.getName() << " :: " << evt.getParentName() << " :: " << evt.getCanvasParentName()<< endl;
        
        for (auto b : synths[evt.getCanvasParentName()]->getBuffers()) {
            if (b == evt.getName()) return;
            else if (b == evt.getParentName()) {
                synths[evt.getCanvasParentName()]->set(evt.getParentName(), buffers[evt.getName()]->index);
                return;
            }
            
        }
        for (auto b : synths[evt.getCanvasParentName()]->getControlBusses()) {
            if (b == evt.getName()) return;
            else if (b == evt.getParentName()) {
                synths[evt.getCanvasParentName()]->set(evt.getParentName(), bussesK[evt.getName()]->index);
                return;
            }
        }
        for (auto b : synths[evt.getCanvasParentName()]->getAudioBusses()) {
            if (b == evt.getName()) return;
            else if (b == evt.getParentName()) {
                if (evt.getName() == "channel_0") {
                    synths[evt.getCanvasParentName()]->set(evt.getParentName(), 0);
                }
                else if (evt.getName() == "channel_1") {
                    synths[evt.getCanvasParentName()]->set(evt.getParentName(), 1);
                }
                else {
                    synths[evt.getCanvasParentName()]->set(evt.getParentName(), bussesA[evt.getName()]->index);
                }
                return;
            }
        }
        
        // go to parameters/gaes
        if (synths[evt.getCanvasParentName()]->getGates().count(evt.getName()) != 0) {
            synths[evt.getCanvasParentName()]->getGates()[evt.getName()]->getParameter().set(evt.getButton()->getValue());
        }
        else if (synths[evt.getCanvasParentName()]->getParameters().count(evt.getName()) != 0) {
            synths[evt.getCanvasParentName()]->getParameters()[evt.getName()]->getParameter().set(evt.getSlider()->getValue());
        }
    }
}
