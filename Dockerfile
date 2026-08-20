FROM sharelatex/sharelatex
RUN tlmgr update --self \
    && tlmgr install scheme-full
