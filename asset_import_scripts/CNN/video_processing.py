import pickle
import random
from pathlib import Path

import cv2
import numpy as np
import pandas as pd
import skvideo.io
from tqdm import tqdm


def get_video_files(video_dir: str, video_ext: str = ".mp4"):
    """ Gets paths of video files at provided directory.

    NOTE: returning simply ``Path(video_dir).glob(f"*.{video_ext}")`` may miss files depending on the capitalization
    of their extensions, at least on Linux

    :param video_ext: the extension of the required video files, defaults to .mp4, MUST include leading dot
    :param video_dir: path of dir with video files
    :return: generator of Paths
    """

    return (v for v in Path(video_dir).glob("*") if v.suffix.lower() == video_ext)


def get_video_rotation(video_path: str):
    """ Reads video rotation from video metadata.

    Works well with .mp4 files, has trouble with .mov files due to different metadata structure.

    :param video_path: path to the video file
    :return: rotation of video in int degrees (e.g. 90, 180)
    :raises AssertionError if rotation is not available, files doesn't exist, or file doesn't have metadata
    """
    metadata = skvideo.io.ffprobe(video_path)
    try:
        for tags in metadata["video"]["tag"]:
            # we get OrderedDicts here
            if tags["@key"] == "rotate":
                return int(tags["@value"])
        else:
            raise AssertionError(f"Couldn't get rotation for {video_path}, either file doesn't exist, does not contain "
                                 f"metadata, or rotation is not included in its metadata.")
    except Exception as e:
        raise e


def extract_video_frames(video_path: Path, rotate: bool = True, resize: bool = True, frame_limiter: int = 1,
                         number_of_frames: int = None, save_as_files: bool = False):
    """ Extracts all frames from the provided video, and optionally saves them as individual images in a directory with
    the same name as the video.

    :param frame_limiter: optional, an integer that limits the number of frames returned; e.g. if equal to 2,
     every second frame will be returned, if 3 every 3rd, etc
    :param number_of_frames: optional, the total number of frames required; in case the video contains fewer frames
     than required, all available frames will be returned; careful when used in conjunction with frame_limiter
    :param video_path: path to the video file
    :param resize: optional, whether to resize frames
    :param rotate: optional, whether to rotate frames
    :param save_as_files: optional, whether to save extracted frames as individual image files
    :return: list of extracted frames
    """
    frame_dest = ""
    if save_as_files:
        # create frame destination dir and make sure it exists
        frame_dest = video_path.parent / video_path.stem
        frame_dest.mkdir(exist_ok=True)

    video_rotation = 0
    try:
        video_rotation = get_video_rotation(str(video_path))
    except AssertionError as ex:
        print(ex)
    except Exception as ex2:  # catch any other exceptions
        print(ex2)

    count = 0

    vidcap = cv2.VideoCapture(str(video_path))
    success, frame = vidcap.read()  # read 1st frame

    all_frames = []

    while success:
        if count % frame_limiter == 0:  # limits the number of frames
            if rotate:
                if video_rotation != 0:
                    frame = rotate_frame(frame, video_rotation)

            if resize:
                frame = resize_frame(frame)

            if save_as_files:
                cv2.imwrite(str(frame_dest / f"{video_path.stem}_{count}.jpg"), frame)

            all_frames.append(np.copy(frame))

        success, frame = vidcap.read()  # read next frame

        count += 1

        if number_of_frames is not None:
            if number_of_frames >= count:
                break

    return all_frames


def rotate_frame(frame: np.ndarray, degrees: int):
    """ Rotates the provided frame 90, 180, or 270 degrees; any other value of degrees is ignored, and the original
    frame is returned un-rotated.

    :param frame: frame to be rotated
    :param degrees: degrees of rotation, must be either 90, 180, or 270, any other values are ignored
    :return: the rotated frame
    """
    if degrees == 90:
        return cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
    elif degrees == 180:
        return cv2.rotate(frame, cv2.ROTATE_180)
    elif degrees == 270:
        return cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)
    else:
        return frame


def resize_frame(frame: np.ndarray, target_dim: int = 224):
    """ Resizes the provided frame to a square with the provided dimension as its sides.

    :param frame: frame to be resized
    :param target_dim: the required side length of the resized frame (optional)
    :return: the resized frame
    """
    return cv2.resize(frame, (target_dim, target_dim), interpolation=cv2.INTER_AREA)


def video_processing(video_files_dir: Path):
    dataset = pd.read_csv(video_files_dir / "description_export.csv")

    # dict with all artwork IDs, as well as a corresponding numerical value
    artwork_dict = {artwork_id: i for i, artwork_id in enumerate(sorted(dataset["id"].unique()))}

    photos, labels = [], []
    t = tqdm(total=dataset.shape[0])
    total_frames = 0

    # process all video files
    for i in range(dataset.shape[0]):
        video_file_row = dataset.iloc[i]

        t.set_postfix_str(f"Processing file {video_file_row['file']} (total frames for far: {total_frames})")

        video_frames = extract_video_frames(video_files_dir / video_file_row["file"])

        frame_labels = [video_file_row["id"]] * len(video_frames)

        photos.extend(video_frames)
        labels.extend(frame_labels)

        total_frames += len(video_frames)
        t.update()

    t.close()

    # return results as a single dict
    return {"photos": photos, "labels": labels}


def save_sample_frames(video_files_dir: Path):
    dataset = pd.read_csv(video_files_dir / "description_export.csv")

    # make new dir to put samples in
    sample_dir = video_files_dir / "artwork_samples_100"
    sample_dir.mkdir(exist_ok=True)

    for i in range(dataset.shape[0]):
        video_file_row = dataset.iloc[i]
        print("extracting from:", video_file_row["id"])

        video_dir = sample_dir / video_file_row['id']
        if not video_dir.is_dir():  # skip video if dir with extracted frames already exists
            video_dir.mkdir()
            video_frames = extract_video_frames(video_files_dir / video_file_row["file"], resize=False,
                                                frame_limiter=8)

            for j, frame in enumerate(random.sample(video_frames, 50)):
                frame_path = video_dir / f"{i}_{j}.jpg"
                cv2.imwrite(str(frame_path), frame)


def unpickle():
    pickled = Path("/home/marios/Downloads/contemporary_art_video_files/processed")
    with open(pickled, "rb") as f:
        f.seek(0)
        dataset = pickle.load(f)


if __name__ == '__main__':
    files_dir = Path("/home/marios/Downloads/contemporary_art_video_files")
    # processed = video_processing(files_dir)
    # with open(files_dir / "processed", "wb+") as f:
    #     pickle.dump(processed, f)
    save_sample_frames(files_dir)