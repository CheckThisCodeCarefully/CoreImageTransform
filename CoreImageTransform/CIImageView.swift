//
// Created by Eduard Panasiuk on 3/12/17.
// Copyright (c) 2017 Eduard Panasiuk. All rights reserved.
//

import Foundation
//GLKit must be linked and imported
import GLKit

class CIImageView: GLKView{
    var image: CIImage?
    var ciContext: CIContext?

    //initialize with the frame, and CIImage to be displayed
    //(or nil, if the image will be set using .setRenderImage)
    init(frame: CGRect, image: CIImage?){
        super.init(frame: frame, context: EAGLContext(api: EAGLRenderingAPI.openGLES2))

        self.image = image
        //Set the current context to the EAGLContext created in the super.init call
        EAGLContext.setCurrent(self.context)
        //create a CIContext from the EAGLContext
        self.ciContext = CIContext(eaglContext: self.context)
    }

    //for usage in Storyboards
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)

        self.context = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        EAGLContext.setCurrent(self.context)
        self.ciContext = CIContext(eaglContext: self.context)
    }

    //set the current image to image
    func setRenderImage(image: CIImage){
        self.image = image

        //tell the processor that the view needs to be redrawn using drawRect()
        self.setNeedsDisplay()
    }

    //called automatically when the view is drawn
    override func draw(_ rect: CGRect){
        glFlush()
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        self.ciContext?.clearCaches()

        //unwrap the current CIImage
        if let image = self.image{
            //multiply the frame by the screen's scale (ratio of points : pixels),
            //because the following .drawImage() call uses pixels, not points
            let scaleH = (rect.size.height * UIScreen.main.scale) / image.extent.height;
            let scaleW = (rect.size.width  * UIScreen.main.scale)  / image.extent.width;
            let scale = (scaleH > scaleW) ? scaleW : scaleH
            let newFrame = CGRect(x:image.extent.minX, y:image.extent.minY, width:image.extent.width * scale, height:image.extent.height * scale)

            //draw the image
            
            self.ciContext?.draw(
                image,
                in: newFrame,
                from: image.extent
            )
        }
    }
}
