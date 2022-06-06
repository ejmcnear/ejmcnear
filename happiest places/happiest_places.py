import pandas as pd
import numpy as np
import matplotlib.pylab as plt
from PIL import Image
from stop_words import get_stop_words
from nltk.corpus import stopwords
import time
from wordcloud import WordCloud, STOPWORDS, ImageColorGenerator, get_single_color_func

#creates a png of a wordcloud of the disneyland reviews in the shape of mickey mouse ears

#read text
data2 = pd.read_csv ('C:/Users/livel/OneDrive/Documents/Tableau Projects/Personal_Projects/Disneyland/DisneylandReviews.csv', usecols = ['Review_Text'], sep = ',', encoding="ISO-8859-1")

start_time = time.time()

a1 =pd.DataFrame (data2)
a3 = pd.DataFrame.to_string(a1)
a0 = a3.upper()

stop = get_stop_words('en')
stop.extend(["thou", "thy", "thee", "dost", "les","park", "go","disney", "disneyland", "just", "place", "can", "one", "get", "ride"])
stopwords = set(stop)

print(stopwords)

building = np.array(Image.open('C://Users/livel/OneDrive/Documents/Tableau Projects/Personal_Projects/Disneyland/ear-mickey-mouse.jpg'))
wordcloud = WordCloud(max_words=3000,
                      stopwords = stopwords, 
                      font_path='C:/Windows/Fonts/courbd.ttf',
                      prefer_horizontal=.7,
                      #colormap='Blues',
                      color_func=lambda *args, **kwargs: (57,47,90),
                      min_font_size=5,
                      max_font_size=70,
                      background_color=None,
                      width=7680,
                      height=4320,
                      margin=2,
                      collocations=False,
                      mask=building,
                      repeat=False,
                      relative_scaling=0,
                      scale=1,
                      min_word_length=3,
                      include_numbers = False,
                      normalize_plurals = False,
                      font_step=1,
                     mode = "RGBA").generate(a0)


print (wordcloud.layout_)
wordcloud.to_file(filename = "C:/Users/livel/OneDrive/Documents/Tableau Projects/Personal_Projects/Disneyland/Mickey_Wordcloud.png")

df = pd.DataFrame(wordcloud.layout_, columns = ['Name', 'Size', 'Coord', 'Direction','Color'])
df.to_csv('C:/Users/livel/OneDrive/Documents/Tableau Projects/Personal_Projects/Disneyland/Mickey_Coordinates.csv')

print(' ')
print ("time elapsed: {:.2f}s".format(time.time() - start_time))

plt.figure(figsize=(30,30))
plt.imshow(wordcloud)
plt.axis("off")
plt.tight_layout(pad=0)
plt.show()
