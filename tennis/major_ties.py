import pandas as pd
import numpy as np
from functools import reduce

filename = "C:/Users/livel/OneDrive/Documents/Tableau Projects/Personal_Projects/Tennis3030/raw_data/2018-wimbledon-points-singles.csv"
tennis_data = pd.read_csv(filename)

def find_tie_winner_prop(df, score, gender = 'both'):
    """returns the proportion of times a player won both the given tied score (0, 15 or 30) and the respective game in a single match"""
    
    #resetting the index of each group so that an out of bounds error isn't thrown
    df.index = df.index -df.index[0]
    
    #find the indices of the rows where tie occurred and add 1 to find the winner of tied point since PointWinner column shows who won the point in the previous row
    pw_index = df.loc[(df['P1Score'] == score) 
                      & (df['P2Score'] == score) 
                      & (df['PointNumber'] != '0X')].index+1
    
    pw_index = list(pw_index)
    
    #ignore index error for matches where no ties occurred
    try:
        pw_index.pop()
    except IndexError:
        pass

    #create a list of tuples of the set - game - pointwinner combos in which tie scores occur to iterate over later
    set_game_pw = list(zip(df.SetNo.loc[(df['P1Score'] == score) & (df['P2Score'] == score)], df.GameNo.loc[(df['P1Score'] == score) & (df['P2Score'] == score)], 
                       df.PointWinner.iloc[pw_index]))
    
    #remove any duplicates as 40-40 can occur multiple times in a game
    set_game_pw = list(dict.fromkeys(set_game_pw))
  
    #loop through the combos to find who won each game in which a tied point occurred, using sum because the gamewinner column contains zeroes for the player number in 
    #all but the final row of each game,where it contains the player number of the game winner
    index = 0
    for i , j, k in set_game_pw:
        gw = sum(df.loc[(df['SetNo'] == int(i)) & (df['GameNo'] == int(j))]['GameWinner'])

        set_game_pw[index] += (gw,)
        index += 1
    
    #ignore cases in which no tied points occurred
    try:
        proportion = sum([1 if x[2] == x[3] else 0 for x in set_game_pw])/len(set_game_pw)
        return proportion
    
    except ZeroDivisionError:
        pass

#function for displaying histogram of proportions of times winner of tied score won the game
def tie_prop_hist(df, score, gender = 'both'):
    """"returns a dataset of the match id's and proportions of times a player who won a tied point of 0-0, 15-15 or 30-30 also won the respective game"""
    
    #split the dataset based on whether one is looking at men's matches, women's matches, or both.  Men's have '1' at beginning of match ID, women's have '2'
    if gender == 'male':
        df = df[df['match_id'].str.match('.*[1][0-9][0-9][0-9]$')== True]
    elif gender == 'female':
        df = df[df['match_id'].str.match('.*[2][0-9][0-9][0-9]$')== True]
    else:
        df = df
    
    #group the datasets by match
    grouped = df.groupby('match_id')
    prop_list = []
    match_id_list=[]
   
    #loop through matches and find the proportion of times player who won the tied point also won the respective game for each match, adding it to a list
    for name, group in grouped:
        prop_list.append(find_tie_winner_prop(group, score, gender))
        match_id_list.append(name)
        
    #convert lists of match id's and proportions into dataframe and plot proportions as a histogram
    proportions_df = pd.DataFrame(
        {'match_ids': match_id_list, 
         score + "-" + score: prop_list})

    return proportions_df

#create lists of proportions using tie_prop_hist function written above then combine lists into dataframe
zeroes = tie_prop_hist(tennis_data, '0')
fifteens = tie_prop_hist(tennis_data, '15')
thirties = tie_prop_hist(tennis_data, '30')
forties = tie_prop_hist(tennis_data, '40')
data_frames = [zeroes, fifteens, thirties, forties]

df_merged = reduce(lambda  left,right: pd.merge(left,right,on=['match_ids'],
                                            how='outer'), data_frames)
df_merged.head()

#create csv from newly created dataframe
df_merged.to_csv("C:/Users/livel/OneDrive/Documents/Tableau Projects/Personal_Projects/Tennis3030/processed_data/wimby2018singles_ties.csv")
