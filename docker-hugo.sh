#!/bin/sh
set -e
# Show commands by default
ECHO="echo"
# Absolute script PATH
CALLER_SCRIPT="$(readlink -f "$0")"
# Absolute PATH to the script's directory
CALLER_SCRIPT_DIR="$(dirname "$CALLER_SCRIPT")"
# Wiki dir
WORKDIR="$(readlink -f "$CALLER_SCRIPT_DIR")"
SCRIPT_NAME="$(basename $0)"
# Get image name from the script name (hugo or nginx-hugo)
IMAGE_NAME="${SCRIPT_NAME##docker-}"
IMAGE_NAME="${IMAGE_NAME%%.sh}"
# Image names for pulling & pushing
PULL_IMAGE="stodh/$IMAGE_NAME"
PUSH_IMAGE="registry.inusdoku.red/$IMAGE_NAME"
# MAIN
case "$IMAGE_NAME" in
hugo|nginx-hugo)
    if [ "$1" = "-x" ]; then ECHO=""; shift 1; fi ;;
*) 
    echo "Unknown image '$IMAGE_NAME'"; exit 1 ;;
esac
# Handle options
OPTION="$1"
[ -z "$OPTION" ] || shift 1
case "$OPTION" in
attach)
    $ECHO docker attach "$IMAGE_NAME" ;;
build)
    [ -z "$1" ] && BUILD_NAME="$IMAGE_NAME" || BUILD_NAME="$IMAGE_NAME:$1";
    $ECHO cd $CALLER_SCRIPT_DIR \; ;
    $ECHO docker build --target "$IMAGE_NAME" -t "$BUILD_NAME" . ;;
exec)
    if [ "$#" -eq "0" ]; then 
        $ECHO docker exec -ti "$IMAGE_NAME" /bin/sh
    else
        $ECHO docker exec -ti "$IMAGE_NAME" "$@"
    fi ;;
logs)
    $ECHO docker logs -f "$IMAGE_NAME" ;;
pull)
    [ -z "$1" ] && PULL_NAME="$PULL_IMAGE" || PULL_NAME="$PULL_IMAGE:$1";
    $ECHO docker pull "$PULL_NAME" ;;
push)
    [ -z "$1" ] && PUSH_NAME="$PUSH_IMAGE" || PUSH_NAME="$PUSH_IMAGE:$1";
    $ECHO docker push "$PUSH_NAME" ;;
run)
    case "$IMAGE_NAME" in
    hugo)
        DOCKER_OPTS="-p 1313:1313";
        DOCKER_OPTS="$DOCKER_OPTS -v ${WORKDIR}:/workdir";
        DOCKER_OPTS="$DOCKER_OPTS -u $(id -u):$(id -g)" ;;
    nginx-hugo)
        DOCKER_OPTS="-p 80:80" ;;
    esac
    $ECHO docker run --interactive --tty --rm=true -d $DOCKER_OPTS \
                     --name "$IMAGE_NAME" "$IMAGE_NAME" "$@";;
stop)
    $ECHO docker stop "$IMAGE_NAME" ;;
tag)
    case "$1" in
    pull)
        [ -z "$2" ] && SOURCE_NAME="$PULL_IMAGE" \
                    || SOURCE_NAME="$PULL_IMAGE:$2";
        [ -z "$3" ] && TARGET_NAME="$IMAGE_NAME" \
                    || TARGET_NAME="$IMAGE_NAME:$3";
    ;;
    push)
        [ -z "$2" ] && SOURCE_NAME="$IMAGE_NAME" \
                    || SOURCE_NAME="$IMAGE_NAME:$2";
        [ -z "$3" ] && TARGET_NAME="$PUSH_IMAGE" \
                  || TARGET_NAME="$PUSH_IMAGE:$3";
    ;;
    *)
        echo "Missing tag option (pull or push)";
        exit 1
    ;;
    esac
    $ECHO docker tag "$SOURCE_NAME" "$TARGET_NAME" ;;
*)
    cat << EOF
Usage: $0 [-x] COMMAND

Where COMMAND can be:

- attach
- build
- exec
- logs
- pull [TAG]
- push [TAG]
- run [ARGS]
- stop
- tag {pull [PULL_TAG] [LOCAL_TAG] | push [LOCAL_TAG] [PUSH_TAG]}

By default the commands to run are shown, when using -x they are executed.
EOF
;;
esac
