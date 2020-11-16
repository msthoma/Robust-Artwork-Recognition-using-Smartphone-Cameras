import csv
from collections import defaultdict
from pathlib import Path


def process_results(results_csv: Path):
    with open(results_csv) as f:
        g = {'filename': 'VID_20201113_114521.mp4', 'timestamp': '35.69400072097776', 'percent': '0.99150002002716',
             'vid_length': '36', 'artworkID': 'crucified_savvides', 'distance': '2.5m', 'clip_type': 'r'}
        res = csv.DictReader(f)

        res_sorted = defaultdict(list)

        # sort timestamps according to their corresponding videos, distances, and clip types
        for r in res:
            res_sorted[(r["filename"], r["artworkID"], r["distance"], r["clip_type"], r["vid_length"])].append(
                float(r["timestamp"]))

        # make sure that no more than 2 timestamps are present for each combination
        assert all(len(v) in [1, 2] for v in res_sorted.values())

        clip_type_conversions = {"f": "forward", "d": "downwards", "u": "upwards", "l": "left", "r": "right"}

        for_excel_video_descriptions = []

        for k, v in res_sorted.items():
            filename, artwork_id, distance, clip_type, vid_length = k
            if len(v) == 1:
                # only "f" clips are allowed to have 1 timestamp, the other being the start of the video, 0.0
                assert clip_type == "f"
                v.append(0.0)
                v.sort()

            # make sure no timestamp exceeds the vid_length
            assert max(v) <= int(vid_length)

            start, end = v

            for_excel_video_descriptions.append({"filename": filename, "artworkID": artwork_id, "distance": distance,
                                                 "clipType": clip_type_conversions[clip_type], "start": start,
                                                 "end": end, "length": end - start})

        with open(results_csv.parent / "testing_videos.csv", "w") as csv_file:
            header = ["filename", "artworkID", "distance", "clipType", "start", "end", "length"]
            writer = csv.DictWriter(csv_file, fieldnames=header)
            writer.writeheader()
            writer.writerows(for_excel_video_descriptions)


def main():
    # process_results(get_script_path() / "clip_timestamps.csv")
    pass


if __name__ == '__main__':
    main()
