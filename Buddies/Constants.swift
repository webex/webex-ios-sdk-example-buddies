// Copyright 2016-2017 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

class Constants {
    
    ///Buddies Client Secret
    static let ClientId = "C267d2f778fcd82715da1d89afa7762a2e8b3b5a36cd5c45b9d5bcc076f99991a"

    static let ClientSecret = "b132058fa39dd4999c62813501e486e396caba1c7c598b9aaae33a629c42a4ce"

    static let RedirectUrl = "sweetie-demo://redirect"

    static let Scope = "spark:all"
    
    class Size {
        static let screenFrame = UIScreen.main.bounds
        static let screenWidth = UIScreen.main.bounds.width
        static let screenHeight = UIScreen.main.bounds.height
        static let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        static let navHeight: CGFloat = {
            if statusBarHeight > 20{
                return 88.0
            }else{
                return 64.0
            }
        }()
        static let tabHeight: CGFloat = {
            if statusBarHeight > 20{
                return 83.0
            }else{
                return 49.0
            }
        }()
    }
    class Webhook {
        
        static let name = "Buddies Incoming Call Webhook"
        
        static let res = "callMemberships"
        
        static let event = "created"
        
        static let filter = "state=notified&personId=me"
        
        static let url = "https://ios-demo-pushnoti-server.herokuapp.com/incoming_call"
        
        static let redirectUrl = "https://ios-demo-pushnoti-server.herokuapp.com/webhook"
        
    }
    
    class Font {
        
        static let SystemFont = ".X-BaiBoard-SysFont"
        
        static let PageNumber = UIFont.safeFont("AvenirNext-Medium", size: 11)!; //UIFont(name: Font.Default, size: 11);
        
        static let AttachmentName = UIFont.safeFont("AvenirNext-Medium", size: 10)!
        
        static let AttachmentPlaceholder = UIFont.safeFont("AvenirNext-Medium", size: 12)!
        
        static let ToolbarButton = UIFont.safeFont("AvenirNext-DemiBold", size: 13)!
        
        static let Indicator = UIFont.safeFont("AvenirNext-DemiBold", size: 14)!
        
        static let StatusBar = UIFont.safeFont("AvenirNext-Medium", size: 13);
        
        class NavigationBar {
            
            static let Title = UIFont.safeFont("AvenirNext-DemiBold", size: 14)!
            
            static let BigTitle =  UIFont.safeFont("AvenirNext-DemiBold", size: 18)!
            
            static let Button = UIFont.safeFont("AvenirNext-Medium", size: 14)!
            
        }
        
        class Side {
            
            static let MainTitle = UIFont.safeFont("AvenirNext-Bold", size: 18)!;
            
            static let SubTitle = UIFont.safeFont("AvenirNext-Bold", size: 16);
            
            static let SectionTitle = UIFont.safeFont("AvenirNext-DemiBold", size: 14);
            
            static let ItemTitle = UIFont.safeFont("AvenirNext-Medium", size: 13);
            
            static let ItemComment = UIFont.safeFont("AvenirNext-Italic", size: 10);
            
            static let BottomText = UIFont.safeFont("AvenirNext-Medium", size: 10);
            
        }
        
        class Table {
            
            static let SectionTitle = UIFont.safeFont("AvenirNext-Bold", size: 14);
            
            static let ItemTitle = UIFont.safeFont("AvenirNext-DemiBold", size: 13)!;
            
            static let ItemDetailTitle = UIFont.safeFont("AvenirNext-Medium", size: 11);
            
        }
        
        class Home {
            
            static let Menu = UIFont.safeFont("AvenirNext-Bold", size: 16)!;
            
            static let Title = UIFont.safeFont("AvenirNext-DemiBold", size: 13)!;
            
            //static let Name = UIFont.safeFont("AvenirNext-DemiBold", size: 14)!;
            
            static let Comment = UIFont.safeFont("AvenirNext-Italic", size: 11)!;
            
            static let Button = UIFont.safeFont("AvenirNext-DemiBold", size: 14)!;
            
        }
        
        class InputBox {
            
            static let Input = UIFont.safeFont("AvenirNext-Medium", size: 14)!
            
            static let Title = UIFont.safeFont("AvenirNext-DemiBold", size: 18)!
            
            static let Comments = UIFont.safeFont("AvenirNext-Italic", size: 11)!
            
            static let Message = UIFont.safeFont("AvenirNext-Medium", size: 11)!
            
            static let Button = UIFont.safeFont("AvenirNext-Medium", size: 16)!
            
            static let Floating = UIFont.safeFont("AvenirNext-DemiBold", size: 8)!
            
            static let Options = UIFont.safeFont("AvenirNext-Medium", size: 12)!
            
        }
        
    }

    class Color {
        
        class Theme {
            
            static let Main = UIColor.init(red: 0.18, green: 0.67, blue: 0.84, alpha: 1)
            
            static let LightMain = UIColor.MKColor.LightBlue.P200
            
            static let Background = UIColor.MKColor.Grey.P300 // KTColor(hue:0, saturation:0, brightness:0.83, alpha:1);
            
            static let LightBackground = UIColor.MKColor.Grey.P200
            
            static let SystemBarBackground = UIColor.MKColor.Grey.P50
            
            static let Shadow = UIColor.lightGray
            
            static let DarkControl = UIColor.MKColor.Grey.P600 // KTColor(hexString: "#6D7277")!;
            
            static let MediumControl = UIColor.MKColor.Grey.P500
            
            static let LightControl = UIColor.MKColor.Grey.P300
            
            static let Highlight = UIColor.MKColor.Amber.P600
            
            static let Warning = UIColor(hexString: "BF3237")!
            
            static let StatusBar = UIColor(hexString: "BF595D")
            
        }
        
        class Table {
            
            static let Background = UIColor(hexString: "EFF0F5")
            
            static let SectionTitle = UIColor(white: 0.6, alpha: 1)
            
            static let ItemTitle = UIColor(white: 0.3, alpha: 1)
            
            static let ItemDetailTitle = UIColor(white: 0.6, alpha: 1)
            
        }
        
        class Message{
            static let PersonMention = UIColor.MKColor.Blue.P900
            
            static let SpaceMention = UIColor.MKColor.Green.P900
            
            static let Link = UIColor.MKColor.Blue.P600
            
            static let Highlight = UIColor.MKColor.Blue.P600
            
            static let Warning = UIColor(hexString: "BF3237")!
            
            static let MineBack = UIColor.MKColor.Blue.P300
            
            static let OtherBack = UIColor.init(red: 0.18, green: 0.67, blue: 0.84, alpha: 1)
            
            static let Text = UIColor.MKColor.Grey.P900
            
        }
    }

}
