//
//  PresentationManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 26/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

protocol PresentationManagerDelegate:class {
    
    func campaignDidFinishWithResponse(view: CampaignView, campaign: Campaign, response: CampaignResponse)
    
}


///Responsible for showing a campaign
class PresentationManager: PresentationManagerDelegate {
    
    static var sharedInstance: PresentationManager = PresentationManager()
    weak var currentShownView: CampaignView?
    
    init () {}
    
    func didRecieveCampaigns(campaigns: [Campaign]) {
        
        ///Show latest first
        let sortedCampaigns = campaigns.sort {
            
            if let d1 = $0.createdAt, d2 = $1.createdAt {
                return d1.compare(d2) == .OrderedAscending
            }else{
                return false
            }
        }
        
        var nextCampaigns = [Campaign]()
        
        if campaigns.count > 1 {
            nextCampaigns = Array(sortedCampaigns.dropFirst())
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
         
            if let firstCampaign = sortedCampaigns.first, type = firstCampaign.messageType  {
                
                switch type {
                    
                case .Announcement:
                    self.showAnnouncmentCampaign(firstCampaign, otherCampaigns: nextCampaigns)
                case .NPS:
                    self.showNPSCampaign(firstCampaign, otherCampaigns: nextCampaigns)
                case .NPSResponse:
                    ()
                }
            }
        }
    }
    
    func showAnnouncmentCampaign(campaign: Campaign, otherCampaigns:[Campaign]) {
        if let announcmentView = AnnouncmentView.fromNib() as? AnnouncmentView where currentShownView == nil {
            
            if let window = UIApplication.sharedApplication().keyWindow {
                currentShownView = announcmentView
                announcmentView.otherCampaigns = otherCampaigns
                announcmentView.campaign = campaign
                announcmentView.delegate = self
                announcmentView.showOnWindow(window)
                                
            }
        }
    }
    
    func showExpandedAnnouncment(campaign: Campaign) {
    
        if let announcmentView = AnnouncmentExpandedView.fromNib() as? AnnouncmentExpandedView, window = UIApplication.sharedApplication().keyWindow {
            
            currentShownView = announcmentView
            announcmentView.campaign = campaign
            announcmentView.delegate = self
            announcmentView.showOnWindow(window)
            
        }
    }
    
    
    func showNPSCampaign(campaign: Campaign, otherCampaigns: [Campaign]) {
     
     
        if let npsContainer = NPSContainerView.fromNib() as? NPSContainerView, npsView = NPSView.fromNib() as? NPSView where currentShownView == nil {
            
            if let window = UIApplication.sharedApplication().keyWindow {
                currentShownView = npsContainer
                npsContainer.delegate = self
                npsContainer.campaign = campaign
                npsView.campaign = campaign
                npsView.otherCampaigns = otherCampaigns
                npsContainer.showOnWindow(window)
                npsContainer.popUpContainer(initialView: npsView)
            }
        }else{
            LoggerManager.log("Error Loading Nib")
        }
    }
    
    ///Presentation Delegate
    
    func campaignDidFinishWithResponse(view: CampaignView, campaign: Campaign, response: CampaignResponse) {
        view.hideFromWindow()
        currentShownView = nil
        switch response {
        case .Announcment(let announcmentResponse):
            if announcmentResponse == .Opened {
                self.showExpandedAnnouncment(campaign)
            }
            CampaignResponseManager.recordAnnouncmentResponse(campaign, response: announcmentResponse)
        case .NPS(let npsResponse):
            CampaignResponseManager.recordNPSResponse(campaign, response: npsResponse)
        }
    }
    
    
}







