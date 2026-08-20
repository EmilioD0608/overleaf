FROM sharelatex/sharelatex
RUN tlmgr update --self && tlmgr install babel-spanish xcolor
