package com.tencent.qcloud.tim.demo.profile;

import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;


import com.tencent.imsdk.v2.V2TIMManager;
import com.tencent.qcloud.tim.demo.R;
import com.tencent.qcloud.tim.demo.utils.Constants;
import com.tencent.qcloud.tuicore.component.MinimalistLineControllerView;
import com.tencent.qcloud.tuicore.component.TitleBarLayout;
import com.tencent.qcloud.tuicore.component.activities.BaseMinimalistLightActivity;
import com.tencent.qcloud.tuicore.component.interfaces.ITitleBarLayout;

public class AboutIMMinimalistActivity extends BaseMinimalistLightActivity implements View.OnClickListener {
    private TitleBarLayout titleBarLayout;
    private MinimalistLineControllerView sdkVersionLv;
    private MinimalistLineControllerView aboutIMLv;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.minimalist_activity_about_im);
        titleBarLayout = findViewById(R.id.about_im_title_bar);
        sdkVersionLv = findViewById(R.id.about_sdk_version_lv);

        aboutIMLv = findViewById(R.id.about_im_lv);
        setupViews();
    }

    private void setupViews() {
        titleBarLayout.getRightIcon().setVisibility(View.GONE);
        titleBarLayout.setTitle(getResources().getString(R.string.about_im), ITitleBarLayout.Position.MIDDLE);
        String sdkVersion = V2TIMManager.getInstance().getVersion();
        sdkVersionLv.setContent(sdkVersion);

        aboutIMLv.setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {
        if (v == aboutIMLv) {
            String title = getResources().getString(R.string.about_im);
            startWebUrl(Constants.IM_ABOUT);
        }
    }

    private void startWebUrl(String url) {
        Intent intent = new Intent();
        intent.setAction(Intent.ACTION_VIEW);
        Uri contentUrl = Uri.parse(url);
        intent.setData(contentUrl);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}