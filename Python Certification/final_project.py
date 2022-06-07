import zipfile

from PIL import Image
import pytesseract
import cv2 as cv
import numpy as np

# loading the face detection classifier
face_cascade = cv.CascadeClassifier('readonly/haarcascade_frontalface_default.xml')

texts = []
with zipfile.ZipFile("readonly/images.zip", mode='r') as imfile:
#     nmlst = imfile.namelist()
#     print(nmlst)

    for lst in imfile.infolist():
        
        #find each article image and convert it to grayscale to hopefully make text easier to detect, then extract text
        origimg = imfile.open(lst.filename)
        img = Image.open(origimg).convert('L')
        text = pytesseract.image_to_string(img)
        
        #detect the faces and create the bounding boxes
        data = imfile.read(lst.filename)       
        cv_img = cv.imdecode(np.frombuffer(data, np.uint8), 1)
        grayimg = cv.cvtColor(cv_img, cv.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(grayimg, 1.3)
        
        # create a list of dictionaries where the key is the image filename and the value 
        # is a list of objects related to the image
        texts.append({lst.filename:[origimg, text, faces]})
        print(lst.filename)

def searchname(name):
    #create a variable for max thumbnail size
    thumbsize = (100, 100)

    with zipfile.ZipFile("readonly/small_img.zip", mode='r') as imfile:
        #iterate through the list of dictionaries created above
        for dict in texts:
            ky = list(dict.keys())[0]
            
            #check to see if each dictionary has the requested name, if it does and there were faces detected, create a contact
            #sheet full of the detected faces and display.
            if name in dict[ky][1]:
                print(f'Results from image: {ky}')
                no_faces = len(dict[ky][2])
                if no_faces > 0:
                    contact_sheet = Image.new(mode = 'RGB', size = (500, 100*-(-(no_faces)//5)))
                    xcoord = 0
                    ycoord = 0
                    img = Image.open(dict[ky][0])

                    for x,y,w,h in dict[ky][2]:

                        cropt = img.crop((x,y,x+w,y+h))
                        cropt.thumbnail(thumbsize)
                        contact_sheet.paste(cropt, (xcoord, ycoord))
                        if xcoord+100 == 500:
                            xcoord = 0
                            ycoord = ycoord+100
                        else:
                            xcoord = xcoord+100
                    display(contact_sheet)
                else:
                    print(f'There were no faces found in {ky}')
            else:
                print(f'"{name}" not found in {ky}')
                
searchname("Mark")
