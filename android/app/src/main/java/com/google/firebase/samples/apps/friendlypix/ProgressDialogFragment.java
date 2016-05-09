/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.firebase.samples.apps.friendlypix;


import android.app.Dialog;
import android.app.ProgressDialog;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;


public class ProgressDialogFragment extends DialogFragment {
    private static final String KEY_TITLE = "title";

    public static ProgressDialogFragment newInstance(String text) {
        ProgressDialogFragment frag = new ProgressDialogFragment();
        frag.setCancelable(false);
        Bundle args = new Bundle();
        args.putString(KEY_TITLE, text);
        frag.setArguments(args);
        return frag;
    }

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        ProgressDialog dialog = new ProgressDialog(getActivity(), getTheme());
        dialog.setMessage(getArguments().getString(KEY_TITLE));
        dialog.setIndeterminate(true);
        dialog.setCancelable(false);
        dialog.setCanceledOnTouchOutside(false);
        return dialog;
    }
}