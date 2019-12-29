Q := @

exist = $(shell if [ -f $(/home/mind890/tools/che/ddk/ddk/toolchains/aarch64-linux-gcc6.3/bin/aarch64-linux-gnu-g++) ]; then echo "exist"; else echo "notexist"; fi;)
ifeq ($(exist), exist)
#exit 0
CPP := g++
else
exit 0
endif

FULL_SRC_FILES        := $(local_src_files)
FULL_INC_DIRS         := $(foreach inc_dir, $(local_inc_dirs), -I$(inc_dir))
SHARED_LIBRARIES      := $(foreach shared_lib, $(local_shared_libs), -l$(shared_lib))
SHARED_LIBRARIES_DIRS := $(foreach shared_lib_dir, $(local_shared_libs_dirs), -L$(shared_lib_dir) -Wl,-rpath-link,$(shared_lib_dir))

LOCAL_OBJ_PATH        := $(LOCAL_DIR)/out
LOCAL_LIBRARY         := $(LOCAL_OBJ_PATH)/$(LOCAL_MODULE_NAME)
FULL_C_SRCS           := $(filter %.c,$(FULL_SRC_FILES))
FULL_C_OBJS           := $(patsubst $(LOCAL_DIR)/%.c,$(LOCAL_OBJ_PATH)/%.o, $(FULL_C_SRCS))
FULL_CPP_SRCS         := $(filter %.cpp,$(FULL_SRC_FILES))
FULL_CPP_OBJS         := $(patsubst $(LOCAL_DIR)/%.cpp,$(LOCAL_OBJ_PATH)/%.o, $(FULL_CPP_SRCS))

all: do_pre_build do_build

do_pre_build:
	$(Q)echo - do [$@]
	$(Q)mkdir -p $(LOCAL_OBJ_PATH)

do_build: $(LOCAL_LIBRARY) | do_pre_build
	$(Q)echo - do [$@]
#	$(Q)rm -rf $(LOCAL_OBJ_PATH)

$(LOCAL_LIBRARY): $(FULL_C_OBJS) $(FULL_CPP_OBJS) | do_pre_build
	$(Q)echo [LD] $@
	$(Q)$(CPP) $(CC_FLAGS) -o $(LOCAL_LIBRARY) $(FULL_C_OBJS) $(FULL_CPP_OBJS) -Wl,--whole-archive  -Wl,--no-whole-archive -Wl,--start-group  -Wl,--end-group $(SHARED_LIBRARIES_DIRS) $(SHARED_LIBRARIES)

$(FULL_C_OBJS): $(LOCAL_OBJ_PATH)/%.o : $(LOCAL_DIR)/%.c  | do_pre_build
	$(Q)echo [CC] $@
	$(Q)mkdir -p $(dir $@)
	$(Q)$(CPP) $(CC_FLAGS)  $(FULL_INC_DIRS) -c $< -o $@

$(FULL_CPP_OBJS): $(LOCAL_OBJ_PATH)/%.o : $(LOCAL_DIR)/%.cpp  | do_pre_build
	$(Q)echo [CC] $@
	$(Q)mkdir -p $(dir $@)
	$(Q)$(CPP) $(CC_FLAGS) $(FULL_INC_DIRS) -c $< -o $@
