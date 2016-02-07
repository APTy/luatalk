local ffi = require('ffi')

ffi.cdef[[
  /*  Sockets  */
  static const int AF_UNIX = 1;
  static const int SOCK_STREAM = 1;

  typedef unsigned short int sa_family_t;
  typedef uint32_t socklen_t;
  typedef int ssize_t;

  struct sockaddr {
    sa_family_t sa_family;
    char sa_data[14];
  };

  struct sockaddr_un {
    sa_family_t sun_family;
    char sun_path[104];
  };

  int socket(int domain, int type, int protocol);
  int bind(int socket, const struct sockaddr *address, socklen_t address_len);
  int listen(int socket, int backlog);
  int accept(int socket, struct sockaddr *address, socklen_t *address_len);
  int connect(int socket, const struct sockaddr *address, socklen_t address_len);
  ssize_t recv(int socket, void *buffer, size_t length, int flags);
  ssize_t send(int socket, const void *buffer, size_t length, int flags);
  int close(int fd);

  /*  Synchronous Polling  */
  static const int POLL_INDEF = -1;
  static const int POLLIN = 0x0001;
  static const int POLLPRI = 0x0002;
  static const int POLLERR = 0x0008;
  static const int POLLHUP = 0x0010;
  static const int POLLNVAL = 0x0020;
  typedef unsigned int nfds_t;

  struct pollfd {
    int fd;
    short events;
    short revents;
  };

  int poll(struct pollfd *fds, nfds_t nfds, int timeout);

  /*  File System  */
  static const int STDIN = 1;
  int unlink(const char *path);
  ssize_t read(int fildes, void *buf, size_t nbyte);

  /*  General  */
  char *strerror(int errnum);
  size_t strlen(const char *s);
  void *memset(void *b, int c, size_t len);
]]
