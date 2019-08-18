//
//  ViewController.swift
//  Count Up
//
//  Created by Ravi Seth on 2018-06-16.
//  Copyright © 2018 Sethco. All rights reserved.
//

/*
 NEXT STEPS
 
 */

import UIKit
import Foundation
import GameKit
import AVFoundation
import AudioToolbox

var root:ViewController = ViewController()
var g:Game? = nil

class ViewController: UIViewController,GKGameCenterControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //DO SOME DELEGATE STUFF FROM EMAIL SENT
        root = self
        authPlayer()
        g = Game()
        g?.delegate = self
        g!.highScore_btn.addTarget(self, action: #selector(self.gCenter_press(_:)), for: .touchUpInside)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        
    }
    //GAME CENTER STUFF////////////////////////////////
    func authPlayer(){
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {
            (view,error) in
            if view != nil{
                self.present(view!, animated: true, completion: nil)
            }
            else{
                //print(GKLocalPlayer.localPlayer().isAuthenticated)
                
            }
        }
    }
    func gSaveScore(number:Int){
        if GKLocalPlayer.localPlayer().isAuthenticated{
            
            var scoreReporter : GKScore
            scoreReporter = GKScore(leaderboardIdentifier: "countup.leaderboard")
            
            scoreReporter.value = Int64(number)
            
            let scoreArray:[GKScore] = [scoreReporter]
            GKScore.report(scoreArray, withCompletionHandler: nil)
        }
    }
    @objc func gCenter_press(_ sender:UIButton!){
        let VC = self.view.window?.rootViewController
        
        let GCVC = GKGameCenterViewController()
        GCVC.gameCenterDelegate = self
        
        VC?.present(GCVC, animated: true, completion: nil)
    }
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    //////////////////////////////////////////


}
class Card{
    var num:Int
    var x:Int = 0
    var y:Int = 0
    
    //LABEL ATTRIBUTES
    var l:UIButton = UIButton()
    var height:CGFloat = 10
    var width:CGFloat = 10
    
    
    
    init(num0:Int){
        self.num = num0
        
    }
    func updateTag(){
        l.tag = x*10+y
    }
    func show(){
        //l.isHidden = false
        l.alpha = 1
    }
    func hide(){
        //l.isHidden = true
        l.alpha = 0
    }
    func updateColour(){
        let r:CGFloat
        let g:CGFloat
        let b:CGFloat
        
        switch num % 5{
        case 0:
            //BLUE
            r = 5
            g = 175
            b = 240
        case 1:
            //LIGHT BLUE
            r = 35
            g = 220
            b = 220
        case 2:
            //RED
            r = 235
            g = 110
            b = 100
        case 3:
            //GREEN
            r = 88
            g = 215
            b = 140
        case 4:
            //LIGHT PURPLE
            r = 200
            g = 120
            b = 230
        default:
            //BLACK
            r = 0
            g = 0
            b = 0
        }
        l.layer.backgroundColor = UIColor(red:r/255.0,green:g/255.0,blue:b/255.0,alpha: 1.0).cgColor
    }
}

class Game{
    var rows = 6
    var cols = 4
    
    var avail_nums:[Card] = []
    var cards:[[Card?]] = [[]]
    var nextCard:Card
    
    var highScore:Int = 0
    var score_lbl:UILabel
    var highScore_btn:UIButton
    
    var hScore_NS = UserDefaults().integer(forKey: "HIGHSCORE")
    var pScore_NS = UserDefaults().integer(forKey: "PREVSCORE")
    
    var time:Int = 5
    var curTime:Int = 5
    var curCountDownTime:Int = 5
    
    var gCenter_lbl:UILabel
    
    var time_lbl:UILabel
    var game_timer:Timer? = nil
    
    var curCount:Int = 0
    
    var winW:CGFloat = UIScreen.main.bounds.width
    var winY:CGFloat = UIScreen.main.bounds.height
    var winH:CGFloat
    var topBar:CGFloat
    
    let play_btn:UIButton
    
    let title_lbl:UILabel
    
    var delegate: ViewController? = nil
    
    //SOUNDS
    var aud : AVAudioPlayer! //INTRO MUSIC
    var aud2 : AVAudioPlayer! //GAME PLAY MUSIC
    var aud3 : AVAudioPlayer! //GOT POINT SOUND
    
    init(){
        
        
        //INITIALZE BOARD
        cards = [[Card?]](repeating: [Card?](repeating: nil, count: cols), count: rows)
        
        nextCard = Card(num0: rows*cols+1)
        
        
        for val in 1...rows*cols{
            avail_nums.append(Card(num0: val))
        }
        topBar = 0.25*winY
        winH = winY - topBar
        
        //INITIALIZE HEADER BUTTONS / LABELS
        gCenter_lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 0.8*winW, height: 0.8*0.5*winY))
        title_lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 0.8*winW, height: 0.8*0.5*winY))
        score_lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 0.8*winW/2, height: 0.4*topBar))
        highScore_btn = UIButton(frame: CGRect(x: 0, y: 0, width: 0.8*winW/2, height: 0.4*topBar))
        time_lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 0.4*topBar, height: 0.4*topBar))
        play_btn = UIButton(frame: CGRect(x: 0, y: 0, width: 0.4*topBar, height: 0.4*topBar))
        
        //play_btn.titleLabel!.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 0.35*winH/CGFloat(rows))!
        time_lbl.font = UIFont(name: "ArialRoundedMTBold", size: 0.35*winH/CGFloat(rows))
        score_lbl.font = UIFont(name: "ArialRoundedMTBold", size: 0.35*winH/CGFloat(rows))
        highScore_btn.titleLabel!.font = UIFont(name: "ArialRoundedMTBold", size: 0.35*winH/CGFloat(rows))
        gCenter_lbl.font = UIFont(name: "ArialRoundedMTBold", size: 0.35*winH/CGFloat(rows)/1.5)
        
        
        score_lbl.textAlignment = .center
        gCenter_lbl.textAlignment = .center
        highScore_btn.titleLabel!.textAlignment = .center
        time_lbl.textAlignment = .center
        
        //play_btn.setTitle("Plashjdhlk", for: .normal)
        score_lbl.text = "Prev: "+String(pScore_NS)
        highScore_btn.setTitle("High: "+String(hScore_NS), for: .normal)
        time_lbl.text = String(time)+"'"
        title_lbl.text = "COUNT\nUP!"
        //gCenter_lbl.text = "GAME CENTER"
        
        gCenter_lbl.numberOfLines = 2
        //GAME CENTER ARROW IMAGE
        let fullString = NSMutableAttributedString(string: "")
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(named: "arrow.png")
        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSAttributedString(attachment: image1Attachment)
        
        // add the NSTextAttachment wrapper to our full string, then add some more text.
        fullString.append(image1String)
        fullString.append(NSAttributedString(string: "\nGAME CENTER"))
        
        // draw the result in a label
        gCenter_lbl.attributedText = fullString

        //MAKE TITLE LABEL ATTRIBUTED
        var mutStr:NSMutableAttributedString
        mutStr = NSMutableAttributedString(string: title_lbl.text!, attributes: [NSAttributedStringKey.font:UIFont(name: "ArialRoundedMTBold", size: title_lbl.frame.height*1/4)])
        //ALTER COLOURS
        mutStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red:0.0/255,green:0.0/255,blue:0.0/255,alpha: 1.0), range: NSRange(location:0,length:4))
        mutStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red:5.0/255,green:175.0/255,blue:240.0/255,alpha: 1), range: NSRange(location:6,length:3))
        
        title_lbl.attributedText = mutStr
        title_lbl.numberOfLines = 2
        
        
        title_lbl.sizeToFit()
        
        score_lbl.textColor = UIColor.black
        score_lbl.layer.backgroundColor = UIColor(red:255.0/255,green:255.0/255,blue:255.0/255,alpha: 0.5).cgColor
        //highScore_lbl.textColor = UIColor.black
        highScore_btn.layer.backgroundColor = UIColor(red:255.0/255,green:255.0/255,blue:255.0/255,alpha: 0.5).cgColor
        time_lbl.textColor = UIColor.black
        //time_lbl.layer.backgroundColor = UIColor(red:255.0/255,green:150.0/255,blue:100.0/255,alpha: 1.0).cgColor
        
        
        time_lbl.layer.borderWidth = 2
        
        play_btn.layer.backgroundColor = UIColor(red:255.0/255,green:255.0/255,blue:255.0/255,alpha: 0.5).cgColor
        play_btn.layer.cornerRadius = 0.3/2*topBar
        score_lbl.layer.cornerRadius = 0.3/2*topBar
        highScore_btn.layer.cornerRadius = 0.3/2*topBar
        play_btn.tag = 1
        
        highScore_btn.setTitleColor(UIColor.black, for: .normal)
        
        time_lbl.layer.cornerRadius = 0.125*topBar
        
        play_btn.center.x = winW/2
        play_btn.center.y = winY/2
        time_lbl.center = play_btn.center
        score_lbl.center.x = winW*0.75
        score_lbl.center.y = 0.55*topBar
        highScore_btn.center.x = winW*0.25
        highScore_btn.center.y = 0.55*topBar
        gCenter_lbl.center.x = winW*0.25
        gCenter_lbl.center.y = 0.55*2*topBar
        title_lbl.center.x = winW/2
        title_lbl.center.y = 0.75*winY
        /*
        score_lbl.center.x = 0.75*winW
        score_lbl.center.y = 0.55*topBar
        time_lbl.center.x = 0.5*winW
        time_lbl.center.y = 0.55*topBar
        play_btn.center.x = 0.25*winW
        play_btn.center.y = 0.55*topBar
         */
        
        play_btn.setImage(UIImage(named:"play.png"), for: .normal)
        play_btn.addTarget(self, action: #selector(self.main), for: .touchUpInside)
        
        play_btn.showsTouchWhenHighlighted = true
        highScore_btn.showsTouchWhenHighlighted = true
        
        
        let colors = Colors()
        root.view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.gl
        backgroundLayer?.frame = root.view.frame
        root.view.layer.insertSublayer(backgroundLayer!, at: 0)
        
        self.formatCard(card: nextCard)
        nextCard.hide()
        self.addView(label: title_lbl)
        self.addView(label: nextCard.l)
        self.addView(label: score_lbl)
        self.addView(label: play_btn)
        self.addView(label: time_lbl)
        self.addView(label: highScore_btn)
        self.addView(label: gCenter_lbl)
        self.scaleView(view: play_btn, x: 1.5, y: 1.5)
        
        time_lbl.alpha = 0
        root.view.bringSubview(toFront: play_btn)
        
        //INITIALIZE SOUNDS
        self.initializeSounds()
        
        
        self.addWiggle(view: title_lbl)
        
    }
    func addWiggle(view:UIView)
    {
        //WIGGLE ANIMATION
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 1
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: title_lbl.center.x-winW/15, y: title_lbl.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: title_lbl.center.x + winW/15, y: title_lbl.center.y))
        
        view.layer.add(animation, forKey: "position")
    }
    func initializeSounds(){
        let path = Bundle.main.path(forResource: "count up intro", ofType: "m4a")
        if path != nil{
            let url = URL(fileURLWithPath: path!)
            do{
                try aud = AVAudioPlayer(contentsOf: url)
                aud.numberOfLoops = -1
                aud.volume = 0.5
                aud.play()
            }catch{
                print(error)
            }
        }
        let path2 = Bundle.main.path(forResource: "count up theme", ofType: "m4a")
        if path2 != nil{
            let url = URL(fileURLWithPath: path2!)
            do{
                try aud2 = AVAudioPlayer(contentsOf: url)
                aud2.volume = 0.5
                aud2.numberOfLoops = -1
                
            }catch{
                print(error)
            }
        }
        
        let path3 = Bundle.main.path(forResource: "points", ofType: "mp3")
        print(path3)
        if path3 != nil{
            let url = URL(fileURLWithPath: path3!)
            do{
                try aud3 = AVAudioPlayer(contentsOf: url)
                aud3.volume = 0.5
                
            }catch{
                print(error)
                
            }
        }
    }
    @objc func main(){
        var t = CGAffineTransform.identity
        t = t.rotated(by: CGFloat(self.play_btn.tag)*CGFloat.pi)
        
        
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        var wx:CGFloat = 0
        
        if play_btn.tag == 0{
            //HOME PAGE
            
            
            aud2.stop()
            aud.currentTime = 0
            aud.play()
            
            self.placeView(view: gCenter_lbl, x: gCenter_lbl.center.x+winW/2, y: gCenter_lbl.center.y)
            
            hideAll_cards()
            self.resetTimer(start: false)
            t = t.scaledBy(x: 1.5, y: 1.5)
            x = winW/2
            y = winY/2
            
            wx = 0.8*winW/2
            
            score_lbl.text = "Prev: "+String(curCount)
            self.placeView(view: highScore_btn, x: highScore_btn.center.x, y: highScore_btn.center.y+winY/4)
            //self.placeView(view: title_lbl, x: title_lbl.center.x, y: title_lbl.center.y-winY/2)
            self.alphaView(view: title_lbl, a: 1.0)
            self.addWiggle(view: title_lbl)
            
            if curCount > UserDefaults().integer(forKey: "HIGHSCORE"){
                UserDefaults.standard.set(curCount, forKey: "HIGHSCORE")
                highScore_btn.setTitle("High: "+String(curCount), for: .normal)
            }
            UserDefaults.standard.set(curCount, forKey: "PREVSCORE")
            
            self.delegate!.gSaveScore(number: curCount)
        }
        else{
            //GAME PAGE
            aud.stop()
            aud2.currentTime = 0
            aud2.play()
            
            self.placeView(view: gCenter_lbl, x: gCenter_lbl.center.x-winW/2, y: gCenter_lbl.center.y)
            curCount = 0
            curCountDownTime = time
            updateScore_lbl()
            self.initializeCard_array()
            showAll_cards()
            
            
            self.resetTimer(start: true)
            self.placeView(view: highScore_btn, x: highScore_btn.center.x, y: highScore_btn.center.y-winY/4)
            
            t = t.scaledBy(x: 1, y: 1)
            
            x = 0.25*winW
            y = 0.55*topBar
            
            wx = 0.4*topBar
            
            //self.placeView(view: title_lbl, x: title_lbl.center.x, y: title_lbl.center.y+winY/2)
            self.alphaView(view: title_lbl, a: 0)
        }
        
        
        
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveLinear, animations: { () -> Void in
            self.play_btn.transform = t
            
            self.play_btn.center.x = x
            self.play_btn.center.y = y
            
            self.time_lbl.center.x = x + x*CGFloat(self.play_btn.tag)
            self.time_lbl.center.y = y
            
            //self.score_lbl.center.x = x + 2*x*CGFloat(self.play_btn.tag)
            //self.score_lbl.center.y = y
            
            self.time_lbl.alpha = CGFloat(self.play_btn.tag)
            //self.score_lbl.alpha = CGFloat(self.play_btn.tag)
            
            let tempX = 0.75*self.winW-wx/2//self.score_lbl.center.x - wx*CGFloat(1-self.play_btn.tag)
            let tempY = self.score_lbl.center.y - self.score_lbl.frame.height/2
            self.score_lbl.frame = CGRect(x: tempX, y: tempY, width: wx, height: 0.4*self.topBar)
        }, completion: {finished in
        })
        
        play_btn.tag = 1 - play_btn.tag
    }
    
    
    
    func initializeCard_array(){
        for e in 0...avail_nums.count - 1{
            avail_nums[e].num = e+1
        }
        nextCard.num = avail_nums.count + 1
        for y in 0...rows-1{
            for x in 0...cols-1{
                let randIdx = Int(arc4random_uniform(UInt32(avail_nums.count)))
                let card = avail_nums[randIdx]
                
                let removeIdx = avail_nums.index(where: { (item) -> Bool in item.num == card.num})
                avail_nums.remove(at: removeIdx!)
                
                
                
                card.x = x
                card.y = y
                cards[y][x] = card
                
                self.formatCard(card: card)
                self.placeCard(card: card)
                card.hide()
                self.addView(label: card.l)
            }
        }
    }
    
    func hideAll_cards(){
        for y in 0...rows-1{
            for x in 0...cols-1{
                let c = cards[y][x]
                //self.removeCard(card: c!)
                self.placeView(view: c!.l, x: winW/2, y: winY/2)
                self.alphaView(view: c!.l, a: 0)
                
                avail_nums.append(c!)
                cards[y][x] = nil
            }
        }
    }
    func showAll_cards(){
        for y in 0...rows-1{
            for x in 0...cols-1{
                let c = cards[y][x]
                if c != nil{
                    self.placeCard(card: c!)
                    //c!.l.center = score_lbl.center
                    self.showCard(card: c!)
                }
                
            }
        }
    }
    func resetTimer(start:Bool){
        game_timer?.invalidate()
        
        if curCount > 0 && curCount % 10 == 0{
            curCountDownTime -= 1
        }
        curTime = curCountDownTime//time
        
        if start{
            initiateTimer()
        }
        else{
            self.updateTimer_lbl()
        }
        
    }
    func updateTimer_lbl(){
        time_lbl.text = String(curTime)+"'"
    }
    func initiateTimer(){
        self.updateTimer_lbl()
        game_timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(countDown), userInfo: nil, repeats: true)
    }
    @objc func countDown(timer:Timer){
        
        curTime -= 1
        self.updateTimer_lbl()
        if curTime == -1{
            //GAME OVER
            //curTime = time+1
            resetTimer(start: false)
            main()
        }
        //initiateTimer()
        
    }
    func addView(label:UIView){
        root.view.addSubview(label)
    }
    func formatCard(card:Card){
        card.height = winH/CGFloat(rows)*0.8
        card.width = winW/CGFloat(cols)*0.8
        card.l = UIButton(frame:CGRect(x: 0, y: 0, width: card.width, height: card.height))
        card.l.setTitle(String(card.num), for: .normal)
        card.l.layer.backgroundColor = UIColor(red:255.0/255,green:100.0/255,blue:100.0/255,alpha: 1.0).cgColor
        card.l.titleLabel!.textAlignment = NSTextAlignment.center
        card.l.titleLabel!.font = UIFont(name: "AppleSDGothicNeo-Bold", size: card.height*0.35)!//card.l.titleLabel!.font.familyName
        card.l.layer.cornerRadius = 0.25*CGFloat(card.width)
        
        card.updateTag()
        card.l.addTarget(self, action: #selector(self.clicked), for: .touchUpInside)
        
        card.l.showsTouchWhenHighlighted = true
        card.updateColour()
    }
    func placeCard(card:Card) -> [CGFloat]{
        let incX = winW/CGFloat(cols)
        let incY = winH/CGFloat(rows)
        
        let xLoc = CGFloat(card.x)*incX+incX/2
        let yLoc = CGFloat(card.y)*incY+incY/2+topBar
        card.l.center = CGPoint(x: xLoc,y:yLoc)
        
        return [xLoc,yLoc]
    }
    func updateScore_lbl(){
        score_lbl.text = String(curCount)
    }
    @objc func clicked(sender:UIButton){
        let loc = sender.tag
        let x = Int(loc/10)
        let y = loc - x*10
        
        let card = cards[y][x]
        
        
        if card == nil{
            return
        }
        if (card!.num) - curCount == 1{
            //POINT
            aud3.currentTime = 0
            aud3.play()
            
            curCount += 1
            
            self.updateScore_lbl()
            
            //card!.hide()
            removeCard(card: card!)
            
            cards[y][x] = nextCard
            nextCard.x = x
            nextCard.y = y
            nextCard.l.setTitle(String(nextCard.num), for: .normal)
            nextCard.updateTag()
            
            nextCard.show()
            self.showCard(card: nextCard)
            
            nextCard.updateColour()
            self.placeCard(card: nextCard)
            
            resetTimer(start: true)
            card!.num = self.nextCard.num + 1
            self.nextCard = card!
            
        }
        else{
            //NO POINT, GAME OVER
            
            main()
        }
    }
    func removeCard(card:Card){
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveLinear, animations: { () -> Void in
            card.l.transform = CGAffineTransform(scaleX: 1/3.0, y: 1/3.0)
                //CGAffineTransform(rotationAngle: CGFloat.pi)
            
            
            card.l.center.x = self.score_lbl.center.x
            card.l.center.y = self.score_lbl.center.y
            card.l.alpha = 0
            
        }, completion: {finished in
            card.l.transform = .identity
        })
    }
    func showCard(card:Card){
        card.l.transform = CGAffineTransform(scaleX: 1/3.0, y: 1/3.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveLinear, animations: { () -> Void in
            card.l.transform = .identity
            
            card.l.alpha = 1.0
            
        }, completion: {finished in
        })
    }
    func alphaView(view:UIView,a:CGFloat){
        view.alpha = 1 - a
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveLinear, animations: { () -> Void in
            view.alpha = a
            
        }, completion: {finished in
        })
    }
    func placeView(view:UIView,x:CGFloat,y:CGFloat){
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveLinear, animations: { () -> Void in
            view.center.x = x
            view.center.y = y
            
        }, completion: {finished in
        })
    }
    func scaleView(view:UIView,x:CGFloat,y:CGFloat){
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveLinear, animations: { () -> Void in
            view.transform = CGAffineTransform(scaleX: x, y: y)
            
        }, completion: {finished in
        })
    }
}
class Colors {
    var gl:CAGradientLayer!
    
    init() {
        let colorBottom = UIColor(red: 200 / 255.0, green: 250.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0).cgColor
        let colorTop = UIColor(red: 255.0 / 255.0, green: 200.0 / 255.0, blue: 100.0 / 255.0, alpha: 1.0).cgColor
        
        self.gl = CAGradientLayer()
        self.gl.colors = [colorTop, colorBottom]
        self.gl.locations = [0.0, 1.0]
    }
}
