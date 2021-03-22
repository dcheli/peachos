#include "file.h"
#include "config.h"
#include "memory/memory.h"
#include "status.h"
#include "memory/heap/kheap.h"
#include "kernel.h"
#include "fat/fat16.h"
#include "disk/disk.h"
#include "string/string.h"
#include "pparser.h"

struct filesystem *filesystems[PEACHOS_MAX_FILESYSTEMS];
struct file_descriptor *file_descriptors[PEACHOS_MAX_FILE_DESCRIPTORS];

static struct filesystem** fs_get_free_filesystem() {
    int i;
    for (i = 0; i < PEACHOS_MAX_FILESYSTEMS; i++) {
        if(filesystems[i] == 0){  // this means the slot is free
            return &filesystems[i];
        }
    }
    return 0;
}

void fs_insert_filesystem(struct filesystem *filesystem) {
    struct filesystem **fs;
    fs = fs_get_free_filesystem();
    if(!fs) {       // this is a system panic
        print("Problem insterting filesystem");
        while(1){}
    }

    *fs = filesystem;       // this fills an entry in the filesystems array
}

//Static filesystems are those that are built into the core kernel
static void fs_static_load() {
    fs_insert_filesystem(fat16_init());

}

// this will load all the available filesystems that we are aware of
void fs_load(){
    memset(filesystems, 0, sizeof(filesystems));
    fs_static_load();
}

// initializes the filesystem
void fs_init(){
    memset(file_descriptors, 0, sizeof(file_descriptors));
    fs_load();
}

static void file_free_descriptor(struct file_descriptor *desc){
    file_descriptors[desc->index-1] = 0x00;
    kfree(desc);
}

static int file_new_descriptor(struct file_descriptor ** desc_out){
    int res = -ENOMEM;
    for(int i = 0; i < PEACHOS_MAX_FILE_DESCRIPTORS; i++){
        if(file_descriptors[i] == 0){
            struct file_descriptor *desc = kzalloc(sizeof(struct file_descriptor));
            // Descriptors start at 1, not 0
            desc->index = i + 1;
            file_descriptors[i] = desc;
            *desc_out = desc;
            res = 0;
            break;
        }
    }
    return res;
}

static struct file_descriptor* file_get_descriptor(int fd){
    if(fd <= 0 || fd >= PEACHOS_MAX_FILE_DESCRIPTORS){
        return 0;
    }
    
    int index = fd - 1;     //descriptors start at 1
    return file_descriptors[index];
}

struct filesystem* fs_resolve(struct disk *disk){
    struct filesystem *fs = 0;
    for(int i = 0; i < PEACHOS_MAX_FILESYSTEMS; i++){
        if(filesystems[i]  != 0 && filesystems[i]->resolve(disk) == 0){
            fs = filesystems[i];
            break;
        }
    }
    return fs;
}


FILE_MODE file_get_mode_by_string(const char * str){
    FILE_MODE mode = FILE_MODE_INVALID;
    if(strncmp(str, "r", 1) == 0){
        mode = FILE_MODE_READ;
    } else if(strncmp(str, "w", 1) == 0){
        mode = FILE_MODE_WRITE;
    } else if(strncmp(str, "a", 1) == 0){
        mode = FILE_MODE_APPEND;
    }

    return mode;

}

// responsible for locating the correct file system to load a file, using the drive number
int fopen(const char *filename, const char *mode_string){
    int res = 0;
    struct path_root *root_path = pathparser_parse(filename, NULL);
    if(!root_path){
        res = -EINVARG;
        goto out;
    }

    // we cannot have just a root path 0:/ should be 0:/test.txt
    // basically prevents someone from trying to open the root directory
    if(!root_path->first){
        res = -EINVARG;
        goto out;
    }

    // Ensures the disk e are reading from exists
    struct disk *disk = disk_get(root_path->drive_no);
    if(!disk){
        res = -EIO;
        goto out;
    }

    // See if the disk has a filesystem associated with it
    if(!disk->filesystem){
        res = -EIO;
        goto out;
    }

    FILE_MODE mode = file_get_mode_by_string(mode_string);
    if(mode == FILE_MODE_INVALID){
        res = -EINVARG;
        goto out;
    }

    void *descriptor_private_data = disk->filesystem->open(disk, root_path->first, mode);
    if(ISERR(descriptor_private_data)){
        res = ERROR_I(descriptor_private_data);
        goto out;
    }

    struct file_descriptor *desc = 0;
    res = file_new_descriptor(&desc);
    if(res < 0){
        goto out;
    }

    desc->filesystem = disk->filesystem;
    desc->private = descriptor_private_data;
    desc->disk = disk;
    res = desc->index;

out:
    // fopen shouldn't return negative values
    if(res < 0)
        res = 0;

    return res;
}

int fstat(int fd, struct file_stat *stat){

    int res = 0;
    struct file_descriptor *desc = file_get_descriptor(fd);
    if(!desc){
        res = -EIO;
        goto out;
    }
    
    res = desc->filesystem->stat(desc->disk, desc->private, stat);
    
out:
    return res;
}

int fclose(int fd){
    int res = 0;
    struct file_descriptor *desc = file_get_descriptor(fd);
    if(!desc){
        res = -EIO;
        goto out;
    }
    res = desc->filesystem->close(desc->private);
    if(res == PEACHOS_ALL_OK){
        file_free_descriptor(desc);
    }

out:
    return res;
}

int fseek(int fd, int offset, FILE_SEEK_MODE whence){
    int res = 0;
    struct file_descriptor *desc = file_get_descriptor(fd);
    if(!desc){
        res = -EIO;
        goto out;
    }

    res = desc->filesystem->seek(desc->private, offset, whence);

out:
    return res;
}

int fread(void *ptr, uint32_t size, uint32_t nmemb, int fd){
    int res = 0;
    if(size == 0 || nmemb == 0 || fd < 1){
        res = -EINVARG;
        goto out;
    }

    struct file_descriptor *desc = file_get_descriptor(fd);
    if(!desc){
        res = -EINVARG;
        goto out;
    }

    res = desc->filesystem->read(desc->disk, desc->private, size, nmemb, (char*) ptr);

out:
    return res;
}
