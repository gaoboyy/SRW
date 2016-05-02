root_dir = $(realpath .)
env_dir = $(root_dir)/env
ext_dir = $(root_dir)/ext_lib
gcc_dir = $(root_dir)/cpp/gcc
py_dir = $(root_dir)/cpp/py
fftw_version = fftw-2.1.5
fftw_dir = $(fftw_version)
fftw_file = $(fftw_version).tar.gz
log_fftw = /dev/null
examples_dir = $(env_dir)/work/srw_python
example10_data_dir = $(examples_dir)/data_example_10

nofftw: core pylib

all: clean fftw core pylib

fftw:
	if [ ! -d "$(ext_dir)" ]; then \
	    mkdir $(ext_dir); \
	    remove_tmp_dir="1"; \
	fi; \
	cd $(ext_dir); \
	if [ ! -f "$(fftw_file)" ]; then \
	    wget https://raw.githubusercontent.com/ochubar/SRW/master/ext_lib/$(fftw_file) > $(log_fftw) 2>&1; \
	fi; \
	if [ -d "$(fftw_dir)" ]; then \
	    rm -rf $(fftw_dir); \
	fi; \
	tar -zxf $(fftw_file); \
	cd $(fftw_dir); \
	./configure --enable-float --with-pic; \
	sed 's/^CFLAGS = /CFLAGS = -fPIC /' -i Makefile; \
	make && cp fftw/.libs/libfftw.a $(ext_dir); \
	cd $(root_dir); \
	rm -rf $(ext_dir)/$(fftw_dir); \
	if [ "$$remove_tmp_dir" == "1" ]; then \
	    rm -rf $(ext_dir); \
	fi;

core: 
	cd $(gcc_dir); make -j8 clean lib

pylib:
	cd $(py_dir); make python

test:
	cd $(examples_dir); timeout 20 python SRWLIB_Example10.py; \
	code=$$?; \
	RED='\033[0;31m'; \
	GREEN='\033[0;32m'; \
	NC='\033[0m'; \
	if [ $$code -eq 0 ]; then \
	    status='PASSED'; \
	    color=$${GREEN}; \
	    message=''; \
	elif [ $$code -eq 124 ]; then \
	    status='PASSED'; \
	    color=$${GREEN}; \
	    message=' (timeouted, expected)'; \
	else \
	    status='FAILED'; \
	    color=$${RED}; \
	    message=''; \
	fi; \
	echo -e "\n\tTest $${color}$${status}$${NC}. Code=$${code}$${message}\n"; \
	rm -f $(example10_data_dir)/{ex10_res_int_se.dat,ex10_res_int_prop_se.dat,ex10_res_int_prop_me.dat};

clean:
	rm -f $(ext_dir)/libfftw.a $(gcc_dir)/libsrw.a $(gcc_dir)/srwlpy.so; \
	rm -rf $(ext_dir)/$(fftw_dir)/ py/build/;
	if [ -d $(root_dir)/.git ]; then git checkout $(examples_dir)/srwlpy.so; fi;

.PHONY: all clean core fftw nofftw pylib test
