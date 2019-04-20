CC = c++
CFLAGS = -I../include/UsageEnvironment
CFLAGS += -I../include/groupsock
CFLAGS += -I../include/liveMedia
CFLAGS += -I../include/BasicUsageEnvironment
CFLAGS += -I. -O2 -DSOCKLEN_T=socklen_t -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64 -Wall -DBSD=1
LIBS = -L../lib/liveMedia -lliveMedia  
LIBS += -L../lib/groupsock -lgroupsock 
LIBS += -L../lib/BasicUsageEnvironment -lBasicUsageEnvironment  
LIBS += -L../lib/UsageEnvironment  -lUsageEnvironment 
testRTSPClient : testRTSPClient.cpp
	    $(CC) $(CFLAGS) -o $@ $^ $(LIBS)

clean:
	    $(RM) testRTSPClient .*.sw?
