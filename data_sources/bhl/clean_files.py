#!/usr/bin/env python3
#
# Process BHL files
# v0.1
# 

import pandas as pd


#creator.txt
data = pd.read_csv("creator.txt", '\t', header = 0)
data.dropna().to_csv("creator2.txt")

#doi.txt
data = pd.read_csv("doi.txt", '\t', header = 0)
data.dropna().to_csv("doi2.txt")

#item.txt
data = pd.read_csv("item.txt", '\t', header = 0)
data.dropna().to_csv("item2.txt")

#pagename.txt
data = pd.read_csv("pagename.txt", '\t', header = 0)
data.dropna().to_csv("pagename2.txt")

#page.txt
data = pd.read_csv("page.txt", '\t', header = 0)
data.dropna().to_csv("page2.txt")

#partcreator.txt
data = pd.read_csv("partcreator.txt", '\t', header = 0)
data.dropna().to_csv("partcreator2.txt")

#part.txt
data = pd.read_csv("part.txt", '\t', header = 0)
data.dropna().to_csv("part2.txt")

#subject.txt
data = pd.read_csv("subject.txt", '\t', header = 0)
data.dropna().to_csv("subject2.txt")

#titleidentifier.txt
data = pd.read_csv("titleidentifier.txt", '\t', header = 0)
data.dropna().to_csv("titleidentifier2.txt")

#title.txt
data = pd.read_csv("title.txt", '\t', header = 0)
data.dropna().to_csv("title2.txt")
